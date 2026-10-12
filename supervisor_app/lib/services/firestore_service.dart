import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import '../models/farmer_tapping_snapshot.dart';
import '../models/sensor_reading.dart';
import '../models/tapping_detail.dart';
import '../models/user_profile.dart';

/// Base URL of `lstm_forecast_service/app.py`. Same "phone can't reach
/// localhost" caveat as `kBackendBaseUrl` in supervisor_route_screen.dart —
/// replace with the laptop's LAN IP for a physical device.
///
/// Runs on a different port from `backend/app.py` (spoilage/route service)
/// on purpose, so the two Flask processes can run side by side.
const String kForecastServiceBaseUrl = 'http://localhost:5001';

/// Base URL of `grade_reason_service/app.py`. Same "phone can't reach
/// localhost" caveat as the other two base URLs — replace with the
/// laptop's LAN IP for a physical device. Runs on its own port so all
/// three Flask processes (spoilage/route, VFA forecast, grade reason)
/// can run side by side.
const String kGradeReasonServiceBaseUrl = 'http://localhost:5002';

/// Result of attempting to auto-trigger a quality forecast after a Grade C
/// collection. This is surfaced to the supervisor UI so a missing-data
/// outcome reads as an explained limitation, not a silent no-op or a crash.
enum ForecastTriggerOutcome {
  skippedNotGradeC,
  queued,
  insufficientData,
  serviceUnreachable,
}

class ForecastTriggerResult {
  final ForecastTriggerOutcome outcome;
  final String message;
  const ForecastTriggerResult(this.outcome, this.message);
}

/// Result of attempting to auto-trigger a Grade-C reason explanation.
/// [insufficientData] covers the model's actual required inputs
/// (pH/temperature/turbidity) being missing from this reading — it does
/// not mean VFA is missing, since the model does not use VFA at all
/// (see grade_reason_service/README.md).
enum GradeReasonTriggerOutcome {
  skippedNotGradeC,
  queued,
  insufficientData,
  serviceUnreachable,
}

class GradeReasonTriggerResult {
  final GradeReasonTriggerOutcome outcome;
  final String message;
  const GradeReasonTriggerResult(this.outcome, this.message);
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'latex_sessions';
  static const String _document = 'live_session';

  /// Sequence/context fields the deployed LSTM requires (model/metadata.json)
  /// that the app's current Firestore schema does not capture anywhere yet:
  /// no lab DRC reading, no weather (temperature/humidity/rainfall), no
  /// storage duration, no collection-gap hours, and no legacy
  /// latex-quantity-in-kg. Per the model's own data-integrity rules, these
  /// are never estimated or defaulted — see lstm_forecast_service/README.md.
  /// Until a real source for these exists, forecast calls will correctly
  /// come back `insufficient_history` / `prediction_data_incomplete` rather
  /// than a fabricated prediction.
  static const List<String> kUnavailableSequenceFields = <String>[
    'drc_value',
    'temperature_c',
    'humidity_percent',
    'rainfall_mm',
    'storage_duration_hours',
    'collection_gap_hours',
    'latex_quantity_kg',
  ];

  // ── Dashboard ────────────────────────────────────────────────

  /// Profile of the currently signed-in user, or null if signed out or the
  /// `users` document is missing.
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return UserProfile.fromMap(doc.id, doc.data()!);
  }

  /// Farmer tapping records, newest first, with each farmer's name resolved
  /// from the `users` collection.
  ///
  /// When [day] is given, only records tapped on that calendar day come back.
  /// The bound is applied in the query rather than to the result, because
  /// [limit] caps the *fetched* window: filtering afterwards would report a
  /// past day as empty whenever its records fall outside the newest [limit].
  ///
  /// Needs no composite index — the range and the sort are both on `date`,
  /// which Firestore indexes on its own.
  Future<List<TappingDetail>> getTappingDetails({
    int limit = 20,
    DateTime? day,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('tapping_details');

    if (day != null) {
      // Half-open range: from midnight up to, but not including, the next
      // midnight. Building the end from the date parts (rather than adding 24
      // hours) keeps month and year rollovers right.
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day + 1);
      query = query
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end);
    }

    final snap = await query
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    final records = snap.docs
        .map((d) => TappingDetail.fromMap(d.id, d.data()))
        .toList();

    // Resolve each distinct farmer once, rather than per record.
    final userIds = records
        .map((r) => r.userId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // A name lookup can fail on its own (e.g. security rules restricting
    // reads of other users' documents). That should cost us the name, not
    // the whole dashboard, so failures fall through to 'Unknown Farmer'.
    final names = <String, String>{};
    await Future.wait(
      userIds.map((id) async {
        try {
          final doc = await _db.collection('users').doc(id).get();
          final data = doc.data();
          if (data != null) names[id] = data['name'] ?? 'Unknown Farmer';
        } catch (_) {
          // Leave unresolved; the caller substitutes a placeholder.
        }
      }),
    );

    return records
        .map((r) => r.copyWith(farmerName: names[r.userId] ?? 'Unknown Farmer'))
        .toList();
  }

  /// Deletes one farmer tapping record and returns the raw document that was
  /// removed, so the caller can offer an undo.
  ///
  /// Firestore has no recycle bin, and this record belongs to the farmer
  /// rather than the supervisor deleting it. Returning the raw map — not a
  /// [TappingDetail], which silently drops any field this app does not parse
  /// — lets [restoreTappingDetail] put the document back exactly as the
  /// farmer app wrote it.
  ///
  /// Returns null when the document is already gone: nothing was deleted, so
  /// there is nothing to restore.
  Future<Map<String, dynamic>?> deleteTappingDetail(String id) async {
    final ref = _db.collection('tapping_details').doc(id);

    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return null;

    await ref.delete();
    return data;
  }

  /// Writes a deleted tapping record back under its original document id.
  ///
  /// Reusing the id matters: the dashboard tracks selections by document id,
  /// and an undo that minted a new id would leave a duplicate-looking record
  /// behind.
  Future<void> restoreTappingDetail(String id, Map<String, dynamic> data) {
    return _db.collection('tapping_details').doc(id).set(data);
  }

  // Listen to Firestore in real-time
  Stream<LatexSession> watchLiveSession() {
    return _db.collection(_collection).doc(_document).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return LatexSession.idle();
      }
      return LatexSession.fromMap(snapshot.data()!);
    });
  }

  /// The most recent `tapping_details` document per farmer, joined with the
  /// `district` and `experience` fields from that farmer's `users` document.
  ///
  /// Backs the collection-route request. `district` and `experience` are not
  /// stored on tapping records — they live on the user profile written at
  /// farmer signup.
  Future<List<FarmerTappingSnapshot>> getLatestTappingPerFarmer() async {
    // The farmer roster drives this, so a farmer with no tapping record yet is
    // still reported (as a snapshot with no tapping) instead of vanishing.
    final usersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'farmer')
        .get();

    final farmers = usersSnap.docs
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .toList();
    if (farmers.isEmpty) return [];

    // One ordered read, grouped in memory — newest-first means the first
    // document seen for a farmer is their latest.
    final tappingSnap = await _db
        .collection('tapping_details')
        .orderBy('date', descending: true)
        .get();

    final latestByUser = <String, TappingDetail>{};
    for (final doc in tappingSnap.docs) {
      final record = TappingDetail.fromMap(doc.id, doc.data());
      if (record.userId.isEmpty) continue;
      latestByUser.putIfAbsent(record.userId, () => record);
    }

    return farmers
        .map(
          (f) => FarmerTappingSnapshot(
            farmerId: f.farmerId,
            userId: f.uid,
            farmerName: f.name,
            district: f.district,
            experience: f.experience,
            tapping: latestByUser[f.uid],
          ),
        )
        .toList();
  }

  /// Opens a collection round covering exactly the farmers the supervisor
  /// selected on the dashboard.
  ///
  /// Farms are seeded with `risk_level: 'pending'` because no sensor has
  /// reported yet — the IoT pipeline fills in VFA, grade and risk, and the
  /// DQN then orders the stops. Coordinates are written only when the farmer
  /// app has supplied them; `has_location` tells the UI which stops can be
  /// mapped and routed.
  Future<void> startSessionForFarms(List<TappingDetail> selected) async {
    final farms = selected
        .map(
          (t) => {
            'farm_id': t.userId,
            'farmer_name': t.farmerName,
            'vfa_result': 0.0,
            'grade': '-',
            'risk_level': 'pending',
            'lat': t.lat ?? 0.0,
            'lng': t.lng ?? 0.0,
            'has_location': t.hasLocation,
            'volume_l': t.latexVolumeL,
          },
        )
        .toList();

    await _db.collection(_collection).doc(_document).set({
      'status': 'uploading',
      'farms': farms,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Simulate IoT sensor upload for testing
  Future<void> simulateSensorUpload() async {
    await _db.collection(_collection).doc(_document).set({
      'status': 'uploading',
      'farms': [],
      'updated_at': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(seconds: 2));
    await _db.collection(_collection).doc(_document).update({
      'status': 'processing',
    });

    await Future.delayed(const Duration(seconds: 3));
    await _db.collection(_collection).doc(_document).update({
      'status': 'ready',
      'farms': [
        {
          'farm_id': 'F001',
          'farmer_name': 'Karunaratne M.',
          'vfa_result': 0.92,
          'grade': 'C',
          'risk_level': 'high',
          'lat': 6.8211,
          'lng': 80.1367,
        },
        {
          'farm_id': 'F002',
          'farmer_name': 'Perera S.K.',
          'vfa_result': 0.61,
          'grade': 'B',
          'risk_level': 'medium',
          'lat': 6.8150,
          'lng': 80.1290,
        },
        {
          'farm_id': 'F003',
          'farmer_name': 'Silva A.R.',
          'vfa_result': 0.38,
          'grade': 'A',
          'risk_level': 'safe',
          'lat': 6.8300,
          'lng': 80.1420,
        },
      ],
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Reset session back to idle
  Future<void> resetSession() async {
    await _db.collection(_collection).doc(_document).set({
      'status': 'idle',
      'farms': [],
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Save a completed collection record.
  ///
  /// [spoilageScore] (0-100, predicted before arrival) and [vfaResult] (the
  /// sensor's chemical reading) are stored under separate keys. `vfa_result`
  /// is written only when a reading exists — never as 0.0, which downstream
  /// consumers such as the LSTM forecasting would read as pristine latex.
  ///
  /// The ammonia fields record preservative dosing at the point of collection.
  Future<GradeReasonTriggerResult?> saveCollection({
    required String farmId,
    required String farmerName,
    required double spoilageScore,
    double? vfaResult,
    String? grade,
    required String riskLevel,
    required double volume,
    required double recommendedAmmoniaL,
    required double actualAmmoniaL,
    required bool followedStandardAmmoniaRatio,
    required String notes,
    SensorReading? reading,
  }) async {
    if (farmId.trim().isEmpty) {
      throw ArgumentError.value(
        farmId,
        'farmId',
        'Farmer Firebase UID is required.',
      );
    }
    if (!volume.isFinite || volume <= 0) {
      throw ArgumentError.value(
        volume,
        'volume',
        'Latex volume must be a finite number greater than zero.',
      );
    }
    if (!actualAmmoniaL.isFinite || actualAmmoniaL < 0) {
      throw ArgumentError.value(
        actualAmmoniaL,
        'actualAmmoniaL',
        'Actual ammonia must be a finite number that is zero or greater.',
      );
    }
    if (!recommendedAmmoniaL.isFinite ||
        (recommendedAmmoniaL - (volume * 0.03)).abs() > 0.000000001) {
      throw ArgumentError.value(
        recommendedAmmoniaL,
        'recommendedAmmoniaL',
        'Recommended ammonia must equal 3% of the latex volume.',
      );
    }

    // Join the farmer's latest tapping record so the collection document
    // contains the farmer-entered field data used later for ML analysis.
    Map<String, dynamic>? tappingData;
    String? tappingDetailId;
    try {
      final tappingSnap = await _db
          .collection('tapping_details')
          .where('userId', isEqualTo: farmId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      if (tappingSnap.docs.isNotEmpty) {
        tappingDetailId = tappingSnap.docs.first.id;
        tappingData = tappingSnap.docs.first.data();
      }
    } catch (_) {
      // Collection saving must still work if an old project has no index.
    }

    final collectionRef = _db.collection('collections').doc();
    await collectionRef.set({
      'collection_id': collectionRef.id,
      'farm_id': farmId,
      'farmer_name': farmerName,
      'tapping_detail_id': ?tappingDetailId,
      'spoilage_risk_score': spoilageScore,
      'vfa_result': ?vfaResult,
      'grade': ?grade,
      'risk_level': riskLevel,
      'volume': volume,
      // Canonical collection fields for future litre-based model retraining.
      // These must not be used as a replacement for the current model's kg input.
      'latex_volume_l': volume,
      'farmer_reported_latex_volume_l': tappingData?['latexVolumeL'],
      'trees_count': tappingData?['treesCount'],
      'tree_condition': tappingData?['treeCondition'],
      'weather_condition': tappingData?['weatherCondition'],
      'tapping_date': tappingData?['date'],
      'tapping_start_time': tappingData?['startTime'],
      'tapping_end_time': tappingData?['endTime'],
      'tapping_duration_minutes': tappingData?['durationMinutes'],
      'yield_per_tree_l':
          (tappingData?['treesCount'] is num &&
              (tappingData?['treesCount'] as num) > 0)
          ? ((tappingData?['latexVolumeL'] as num?)?.toDouble() ?? 0) /
                (tappingData?['treesCount'] as num).toDouble()
          : null,
      'recommended_ammonia_l': recommendedAmmoniaL,
      'recommended_ammonia_ratio': 0.03,
      'actual_ammonia_l': actualAmmoniaL,
      'actual_ammonia_ratio': actualAmmoniaL / volume,
      'followed_standard_ammonia_ratio': followedStandardAmmoniaRatio,
      // Full sensor context, so a collection is traceable back to the exact
      // probe sample that graded it.
      if (reading != null) ...{
        'sensor_sample_id': reading.sampleId,
        'sensor_ph': reading.ph,
        'sensor_temperature': reading.temperature,
        'sensor_turbidity': reading.turbidity,
        'sensor_reading_at': reading.timestamp?.toIso8601String(),
        'sensor_captured_at': DateTime.now().toIso8601String(),
      },
      'notes': notes,
      'collected_at': FieldValue.serverTimestamp(),
      'grade_status': grade == 'C' ? 'requires_improvement' : 'accepted',
    });

    if (grade?.trim().toUpperCase() == 'C') {
      // Best-effort: a grade-C collection should prompt a fresh quality
      // forecast for the farmer's dashboard, but a slow/offline forecast
      // service must never fail or delay the collection save that already
      // succeeded above.
      try {
        await triggerQualityForecast(farmId);
      } catch (_) {
        // Swallowed deliberately — see triggerQualityForecast's own
        // exception handling for why, and call it directly for a status.
      }

      // Same best-effort contract as above, for the separate "why is this
      // Grade C" explanation. The service can still write a useful
      // contextual explanation when the sensor was skipped; it reports the
      // missing sensor fields instead of silently omitting the alert.
      try {
        return await triggerGradeReason(
          farmId,
          reading,
          vfa: vfaResult,
          grade: 'C',
          collectionId: collectionRef.id,
          latexVolumeL: volume,
          treesCount: (tappingData?['treesCount'] as num?)?.toInt(),
          storageDurationHours: _storageDurationHours(tappingData),
          actualAmmoniaRatio: actualAmmoniaL / volume,
          weatherCondition: tappingData?['weatherCondition']?.toString(),
          treeCondition: tappingData?['treeCondition']?.toString(),
        );
      } catch (_) {
        // Swallowed deliberately, same rationale as triggerQualityForecast.
      }
    }
    return null;
  }

  /// Collection records saved today. Each map includes '_id', the Firestore
  /// document id, so a record can be looked up again later (e.g. for
  /// [correctCollectionGrade]) without a second query.
  Future<List<Map<String, dynamic>>> getTodaysCollections() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snap = await _db
        .collection('collections')
        .where('collected_at', isGreaterThanOrEqualTo: startOfDay)
        .get();

    return snap.docs
        .map((d) => <String, dynamic>{...d.data(), '_id': d.id})
        .toList();
  }

  /// Corrects the grade on an already-saved `collections/{collectionId}`
  /// document from within the app, instead of editing Firestore by hand.
  ///
  /// This matters because [triggerGradeReason] and [triggerQualityForecast]
  /// are plain Dart calls that only run when *this app's* code executes them
  /// -- there is no Firestore-triggered Cloud Function in this project
  /// watching `collections` for changes. A grade edited directly in the
  /// Firebase console (or any other external tool) will never invoke either
  /// service, so `grade_alerts/{userId}` is never written and the farmer's
  /// "Why was your latex Grade C?" card never appears. Routing the
  /// correction through this method is what makes the notification fire.
  ///
  /// Re-triggers the Grade-C explanation using the sensor readings already
  /// stored on the record (`sensor_ph` / `sensor_temperature` /
  /// `sensor_turbidity`, written by [saveCollection]). If the record predates
  /// those fields, a contextual explanation is still generated with the
  /// missing sensor fields clearly reported.
  Future<GradeReasonTriggerResult> correctCollectionGrade(
    String collectionId,
    String newGrade,
  ) async {
    final docRef = _db.collection('collections').doc(collectionId);
    final snap = await docRef.get();
    final data = snap.data();
    if (data == null) {
      return const GradeReasonTriggerResult(
        GradeReasonTriggerOutcome.insufficientData,
        'That collection record no longer exists.',
      );
    }

    await docRef.update(<String, dynamic>{
      'grade': newGrade,
      'grade_corrected_at': FieldValue.serverTimestamp(),
    });

    if (newGrade != 'C') {
      return const GradeReasonTriggerResult(
        GradeReasonTriggerOutcome.skippedNotGradeC,
        'Grade updated.',
      );
    }

    final farmId = (data['farm_id'] ?? '').toString();
    final double? ph = (data['sensor_ph'] as num?)?.toDouble();
    final double? temperature = (data['sensor_temperature'] as num?)
        ?.toDouble();
    final double? turbidity = (data['sensor_turbidity'] as num?)?.toDouble();
    final double? vfaResult = (data['vfa_result'] as num?)?.toDouble();

    if (farmId.isEmpty) {
      return const GradeReasonTriggerResult(
        GradeReasonTriggerOutcome.insufficientData,
        'Grade updated, but this record has no farmer identity for the explanation.',
      );
    }

    final reading = ph != null || temperature != null || turbidity != null
        ? SensorReading(
            key: (data['sensor_sample_id'] ?? collectionId).toString(),
            sampleId: (data['sensor_sample_id'] ?? '').toString(),
            ph: ph,
            temperature: temperature,
            turbidity: turbidity,
            vfa: vfaResult,
          )
        : null;

    try {
      await triggerQualityForecast(farmId);
    } catch (_) {
      // Best-effort, same rationale as saveCollection.
    }

    final double? volume = (data['latex_volume_l'] as num?)?.toDouble();
    final int? trees = (data['trees_count'] as num?)?.toInt();
    return triggerGradeReason(
      farmId,
      reading,
      vfa: vfaResult,
      grade: newGrade,
      collectionId: collectionId,
      latexVolumeL: volume,
      treesCount: trees,
      storageDurationHours: (data['storage_duration_hours'] as num?)
          ?.toDouble(),
      actualAmmoniaRatio: (data['actual_ammonia_ratio'] as num?)?.toDouble(),
      weatherCondition: data['weather_condition']?.toString(),
      treeCondition: data['tree_condition']?.toString(),
    );
  }

  double? _storageDurationHours(Map<String, dynamic>? tappingData) {
    if (tappingData == null) return null;
    final dynamic dateValue = tappingData['date'];
    final dynamic startValue = tappingData['startTime'];
    if (dateValue is! Timestamp || startValue is! String) return null;
    final parts = startValue.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final start = DateTime(
      dateValue.toDate().year,
      dateValue.toDate().month,
      dateValue.toDate().day,
      h,
      m,
    );
    final hours = DateTime.now().difference(start).inMinutes / 60.0;
    return hours.isFinite && hours >= 0 ? hours : null;
  }

  /// Calls the LSTM forecast service for [userId] and asks it to persist the
  /// result to `quality_forecasts/{userId}` (write access from the client is
  /// blocked by firestore.rules; only the service's Admin SDK identity may
  /// write that document — see firestore.rules and lstm_forecast_service/app.py).
  ///
  /// Builds `sequenceRecords` from this farmer's real `collections` history.
  /// It never invents a value for a field the schema doesn't capture yet
  /// (see [kUnavailableSequenceFields]); when required fields are missing,
  /// the service correctly refuses to predict and this returns
  /// [ForecastTriggerOutcome.insufficientData] with the service's own
  /// explanation, rather than silently producing no forecast at all.
  Future<ForecastTriggerResult> triggerQualityForecast(String userId) async {
    try {
      final history = await _db
          .collection('collections')
          .where('farm_id', isEqualTo: userId)
          .orderBy('collected_at', descending: true)
          .limit(30)
          .get();

      final List<Map<String, dynamic>> sequenceRecords = history.docs.map((
        doc,
      ) {
        final data = doc.data();
        final Timestamp? collectedAt = data['collected_at'] as Timestamp?;
        return <String, dynamic>{
          // Only fields this schema genuinely records. Missing keys are left
          // out entirely rather than defaulted — see kUnavailableSequenceFields.
          'vfa_value': data['vfa_result'],
          'ammonia_amount_ml': (data['actual_ammonia_l'] is num)
              ? (data['actual_ammonia_l'] as num) * 1000
              : null,
          'ammonia_added': (data['actual_ammonia_l'] is num)
              ? ((data['actual_ammonia_l'] as num) > 0 ? 1 : 0)
              : null,
          'capturedAt': collectedAt?.toDate().toIso8601String(),
        };
      }).toList();

      final DateTime now = DateTime.now();
      final Map<String, dynamic> context = <String, dynamic>{
        'tapping_hour': now.hour,
        'doy_sin': _doySin(now),
        'doy_cos': _doyCos(now),
        // 'temperature_c', 'humidity_percent', 'rainfall_mm',
        // 'storage_duration_hours', 'collection_gap_hours',
        // 'latex_quantity_kg', 'drc_value', 'days_since_last':
        // intentionally omitted — not captured by this app's schema yet.
      };

      final response = await http.post(
        Uri.parse('$kForecastServiceBaseUrl/forecast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
          'sequenceRecords': sequenceRecords,
          'context': context,
          'forecastDate': now.toIso8601String(),
          'saveToFirestore': true,
        }),
      );

      if (response.statusCode == 200) {
        return const ForecastTriggerResult(
          ForecastTriggerOutcome.queued,
          'Quality forecast updated for this farmer.',
        );
      }

      // The service replies 422 with a precise reason (insufficient_history
      // or prediction_data_incomplete) rather than a prediction — surface
      // that reason as-is instead of a generic failure.
      String reason = 'The forecast service could not run a prediction.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        reason = (body['message'] ?? reason).toString();
      } catch (_) {
        // Non-JSON error body; keep the generic reason.
      }
      return ForecastTriggerResult(
        ForecastTriggerOutcome.insufficientData,
        reason,
      );
    } catch (_) {
      return const ForecastTriggerResult(
        ForecastTriggerOutcome.serviceUnreachable,
        'Could not reach the forecast service. Is lstm_forecast_service running?',
      );
    }
  }

  /// Calls the Grade-C reason service for [userId] and asks it to persist
  /// the explanation to `grade_alerts/{userId}` (client writes to that
  /// collection are blocked in firestore.rules; only the service's Admin
  /// SDK identity may write it — same shape as quality_forecasts).
  ///
  /// The underlying model (grade_reason_service/README.md) was trained on
  /// pH, temperature and turbidity only — VFA is not one of its inputs, so
  /// [vfa] and [grade] are sent purely as context for display, never as
  /// something the model reasons over. [reading] supplies the three values
  /// the model actually needs when available. A null reading still produces
  /// a contextual alert and clearly reports the missing sensor fields.
  Future<GradeReasonTriggerResult> triggerGradeReason(
    String userId,
    SensorReading? reading, {
    double? vfa,
    String? grade,
    String? collectionId,
    double? latexVolumeL,
    int? treesCount,
    double? storageDurationHours,
    double? actualAmmoniaRatio,
    String? weatherCondition,
    String? treeCondition,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kGradeReasonServiceBaseUrl/grade-reason'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'userId': userId,
              if (reading?.ph != null) 'ph': reading!.ph,
              if (reading?.temperature != null)
                'temperature': reading!.temperature,
              if (reading?.turbidity != null) 'turbidity': reading!.turbidity,
              'vfa': ?vfa,
              'grade': ?grade,
              'collectionId': ?collectionId,
              'latex_volume_l': ?latexVolumeL,
              'trees_count': ?treesCount,
              'storage_duration_hours': ?storageDurationHours,
              'actual_ammonia_ratio': ?actualAmmoniaRatio,
              'weather_condition': ?weatherCondition,
              'tree_condition': ?treeCondition,
              'saveToFirestore': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const GradeReasonTriggerResult(
          GradeReasonTriggerOutcome.queued,
          'Grade explanation updated for this farmer.',
        );
      }

      String reason = 'The grade-reason service could not run a prediction.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        reason = (body['message'] ?? reason).toString();
      } on TimeoutException {
        return const GradeReasonTriggerResult(
          GradeReasonTriggerOutcome.serviceUnreachable,
          'The Grade C service timed out while saving the farmer notification.',
        );
      } catch (_) {
        // Non-JSON error body; keep the generic reason.
      }
      return GradeReasonTriggerResult(
        GradeReasonTriggerOutcome.insufficientData,
        reason,
      );
    } catch (_) {
      return const GradeReasonTriggerResult(
        GradeReasonTriggerOutcome.serviceUnreachable,
        'Could not reach the grade-reason service. Is grade_reason_service running?',
      );
    }
  }

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year, 1, 1)).inDays;

  static double _doySin(DateTime d) =>
      math.sin(2 * math.pi * _dayOfYear(d) / 365.25);

  static double _doyCos(DateTime d) =>
      math.cos(2 * math.pi * _dayOfYear(d) / 365.25);

  /// Farm ids already collected today, so a round survives an app restart
  /// without offering stops the supervisor has finished.
  Future<Set<String>> getFarmIdsCollectedToday() async {
    final records = await getTodaysCollections();
    return records
        .map((r) => (r['farm_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }
}

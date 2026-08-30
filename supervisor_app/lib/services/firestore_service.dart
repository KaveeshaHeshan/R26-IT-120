import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm.dart';
import '../models/farmer_tapping_snapshot.dart';
import '../models/sensor_reading.dart';
import '../models/tapping_detail.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'latex_sessions';
  static const String _document   = 'live_session';

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

  /// Most recent farmer tapping records, newest first, with each farmer's
  /// name resolved from the `users` collection.
  Future<List<TappingDetail>> getTappingDetails({int limit = 20}) async {
    final snap = await _db
        .collection('tapping_details')
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
    await Future.wait(userIds.map((id) async {
      try {
        final doc = await _db.collection('users').doc(id).get();
        final data = doc.data();
        if (data != null) names[id] = data['name'] ?? 'Unknown Farmer';
      } catch (_) {
        // Leave unresolved; the caller substitutes a placeholder.
      }
    }));

    return records
        .map((r) => r.copyWith(
              farmerName: names[r.userId] ?? 'Unknown Farmer',
            ))
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
    return _db
        .collection(_collection)
        .doc(_document)
        .snapshots()
        .map((snapshot) {
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
        .map((f) => FarmerTappingSnapshot(
              farmerId: f.farmerId,
              userId: f.uid,
              farmerName: f.name,
              district: f.district,
              experience: f.experience,
              tapping: latestByUser[f.uid],
            ))
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
    final farms = selected.map((t) => {
          'farm_id':      t.userId,
          'farmer_name':  t.farmerName,
          'vfa_result':   0.0,
          'grade':        '-',
          'risk_level':   'pending',
          'lat':          t.lat ?? 0.0,
          'lng':          t.lng ?? 0.0,
          'has_location': t.hasLocation,
          'volume_l':     t.latexVolumeL,
        }).toList();

    await _db.collection(_collection).doc(_document).set({
      'status':     'uploading',
      'farms':      farms,
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
          'farm_id':     'F001',
          'farmer_name': 'Karunaratne M.',
          'vfa_result':  0.92,
          'grade':       'C',
          'risk_level':  'high',
          'lat':         6.8211,
          'lng':         80.1367,
        },
        {
          'farm_id':     'F002',
          'farmer_name': 'Perera S.K.',
          'vfa_result':  0.61,
          'grade':       'B',
          'risk_level':  'medium',
          'lat':         6.8150,
          'lng':         80.1290,
        },
        {
          'farm_id':     'F003',
          'farmer_name': 'Silva A.R.',
          'vfa_result':  0.38,
          'grade':       'A',
          'risk_level':  'safe',
          'lat':         6.8300,
          'lng':         80.1420,
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
  Future<void> saveCollection({
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
    if (!volume.isFinite || volume <= 0) {
      throw ArgumentError.value(
          volume, 'volume', 'Latex volume must be a finite number greater than zero.');
    }
    if (!actualAmmoniaL.isFinite || actualAmmoniaL < 0) {
      throw ArgumentError.value(actualAmmoniaL, 'actualAmmoniaL',
          'Actual ammonia must be a finite number that is zero or greater.');
    }
    if (!recommendedAmmoniaL.isFinite ||
        (recommendedAmmoniaL - (volume * 0.03)).abs() > 0.000000001) {
      throw ArgumentError.value(recommendedAmmoniaL, 'recommendedAmmoniaL',
          'Recommended ammonia must equal 3% of the latex volume.');
    }

    await _db.collection('collections').add({
      'farm_id':      farmId,
      'farmer_name':  farmerName,
      'spoilage_risk_score': spoilageScore,
      if (vfaResult != null) 'vfa_result': vfaResult,
      if (grade != null) 'grade': grade,
      'risk_level':   riskLevel,
      'volume':       volume,
      // Canonical collection fields for future litre-based model retraining.
      // These must not be used as a replacement for the current model's kg input.
      'latex_volume_l': volume,
      'recommended_ammonia_l': recommendedAmmoniaL,
      'recommended_ammonia_ratio': 0.03,
      'actual_ammonia_l': actualAmmoniaL,
      'actual_ammonia_ratio': actualAmmoniaL / volume,
      'followed_standard_ammonia_ratio': followedStandardAmmoniaRatio,
      // Full sensor context, so a collection is traceable back to the exact
      // probe sample that graded it.
      if (reading != null) ...{
        'sensor_sample_id':   reading.sampleId,
        'sensor_ph':          reading.ph,
        'sensor_temperature': reading.temperature,
        'sensor_turbidity':   reading.turbidity,
        'sensor_reading_at':  reading.timestamp?.toIso8601String(),
        'sensor_captured_at': DateTime.now().toIso8601String(),
      },
      'notes':        notes,
      'collected_at': FieldValue.serverTimestamp(),
    });
  }

  /// Collection records saved today.
  Future<List<Map<String, dynamic>>> getTodaysCollections() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snap = await _db
        .collection('collections')
        .where('collected_at', isGreaterThanOrEqualTo: startOfDay)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

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

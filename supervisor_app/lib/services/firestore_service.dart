import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'latex_sessions';
  static const String _document   = 'live_session';

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
  // Save completed collection record
Future<void> saveCollection({
  required String farmId,
  required String farmerName,
  required double vfaResult,
  required String grade,
  required String riskLevel,
  required double volume,
  required double recommendedAmmoniaL,
  required double actualAmmoniaL,
  required bool followedStandardAmmoniaRatio,
  required String notes,
}) async {
  if (!volume.isFinite || volume <= 0) {
    throw ArgumentError.value(volume, 'volume', 'Latex volume must be a finite number greater than zero.');
  }
  if (!actualAmmoniaL.isFinite || actualAmmoniaL < 0) {
    throw ArgumentError.value(actualAmmoniaL, 'actualAmmoniaL', 'Actual ammonia must be a finite number that is zero or greater.');
  }
  if (!recommendedAmmoniaL.isFinite || (recommendedAmmoniaL - (volume * 0.03)).abs() > 0.000000001) {
    throw ArgumentError.value(recommendedAmmoniaL, 'recommendedAmmoniaL', 'Recommended ammonia must equal 3% of the latex volume.');
  }

  await _db.collection('collections').add({
    'farm_id':     farmId,
    'farmer_name': farmerName,
    'vfa_result':  vfaResult,
    'grade':       grade,
    'risk_level':  riskLevel,
    'volume':      volume,
    // Canonical collection fields for future litre-based model retraining.
    // These must not be used as a replacement for the current model's kg input.
    'latex_volume_l': volume,
    'recommended_ammonia_l': recommendedAmmoniaL,
    'recommended_ammonia_ratio': 0.03,
    'actual_ammonia_l': actualAmmoniaL,
    'actual_ammonia_ratio': actualAmmoniaL / volume,
    'followed_standard_ammonia_ratio': followedStandardAmmoniaRatio,
    'notes':       notes,
    'collected_at': FieldValue.serverTimestamp(),
  });
  }
}

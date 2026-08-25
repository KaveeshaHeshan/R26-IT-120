import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm.dart';
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
  required String notes,
}) async {
  await _db.collection('collections').add({
    'farm_id':     farmId,
    'farmer_name': farmerName,
    'vfa_result':  vfaResult,
    'grade':       grade,
    'risk_level':  riskLevel,
    'volume':      volume,
    'notes':       notes,
    'collected_at': FieldValue.serverTimestamp(),
  });
  }
}

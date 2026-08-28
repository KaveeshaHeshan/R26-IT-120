import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class OfflineQueueService {
  static const String _key = 'pending_collections';

  // Add a collection to the local offline queue
  Future<void> addPendingCollection({
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
    final prefs = await SharedPreferences.getInstance();
    final pending = await _getRawList(prefs);

    pending.add({
      'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'farm_id': farmId,
      'farmer_name': farmerName,
      'vfa_result': vfaResult,
      'grade': grade,
      'risk_level': riskLevel,
      'volume': volume,
      'recommended_ammonia_l': recommendedAmmoniaL,
      'actual_ammonia_l': actualAmmoniaL,
      'followed_standard_ammonia_ratio': followedStandardAmmoniaRatio,
      'notes': notes,
      'queued_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_key, jsonEncode(pending));
  }

  // Get all pending (unsynced) collections
  Future<List<Map<String, dynamic>>> getPendingCollections() async {
    final prefs = await SharedPreferences.getInstance();
    return _getRawList(prefs);
  }

  Future<int> get pendingCount async => (await getPendingCollections()).length;

  // Try to push everything in the queue to Firestore.
  // Successful items are removed; failed ones stay queued for next try.
  Future<void> syncPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await _getRawList(prefs);
    if (pending.isEmpty) return;

    final service = FirestoreService();
    final stillPending = <Map<String, dynamic>>[];

    for (final item in pending) {
      try {
        // Older queued records predate the litre-based ammonia fields. Use
        // the standard 3% amount as a conservative migration default so an
        // existing offline queue does not become permanently unsyncable.
        final volume = (item['volume'] as num).toDouble();
        final recommendedAmmonia = item['recommended_ammonia_l'] is num
            ? (item['recommended_ammonia_l'] as num).toDouble()
            : volume * 0.03;
        final actualAmmonia = item['actual_ammonia_l'] is num
            ? (item['actual_ammonia_l'] as num).toDouble()
            : recommendedAmmonia;
        final followedStandard = item['followed_standard_ammonia_ratio'] is bool
            ? item['followed_standard_ammonia_ratio'] as bool
            : true;
        await service.saveCollection(
          farmId: item['farm_id'],
          farmerName: item['farmer_name'],
          vfaResult: (item['vfa_result'] as num).toDouble(),
          grade: item['grade'],
          riskLevel: item['risk_level'],
          volume: volume,
          recommendedAmmoniaL: recommendedAmmonia,
          actualAmmoniaL: actualAmmonia,
          followedStandardAmmoniaRatio: followedStandard,
          notes: item['notes'],
        );
        // synced successfully — drop it from the queue
      } catch (e) {
        // still offline / failed — keep it queued
        stillPending.add(item);
      }
    }

    await prefs.setString(_key, jsonEncode(stillPending));
  }

  Future<List<Map<String, dynamic>>> _getRawList(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}

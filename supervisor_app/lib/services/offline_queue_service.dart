import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class OfflineQueueService {
  static const String _key = 'pending_collections';

  // Add a collection to the local offline queue
  Future<void> addPendingCollection({
    required String farmId,
    required String farmerName,
    required double spoilageScore,
    double? vfaResult,
    String? grade,
    required String riskLevel,
    required double volume,
    required String notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await _getRawList(prefs);

    pending.add({
      'local_id':   DateTime.now().millisecondsSinceEpoch.toString(),
      'farm_id':    farmId,
      'farmer_name': farmerName,
      'spoilage_risk_score': spoilageScore,
      // Omitted entirely when no sensor reading exists, so a queued record
      // never invents a VFA value.
      if (vfaResult != null) 'vfa_result': vfaResult,
      if (grade != null) 'grade': grade,
      'risk_level': riskLevel,
      'volume':     volume,
      'notes':      notes,
      'queued_at':  DateTime.now().toIso8601String(),
    });

    await prefs.setString(_key, jsonEncode(pending));
  }

  // Get all pending (unsynced) collections
  Future<List<Map<String, dynamic>>> getPendingCollections() async {
    final prefs = await SharedPreferences.getInstance();
    return _getRawList(prefs);
  }

  Future<int> get pendingCount async =>
      (await getPendingCollections()).length;

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
        await service.saveCollection(
          farmId:     item['farm_id'],
          farmerName: item['farmer_name'],
          spoilageScore: (item['spoilage_risk_score'] as num?)?.toDouble() ?? 0.0,
          vfaResult:  (item['vfa_result'] as num?)?.toDouble(),
          grade:      item['grade'] as String?,
          riskLevel:  item['risk_level'],
          volume:     (item['volume'] as num).toDouble(),
          notes:      item['notes'],
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
      SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}
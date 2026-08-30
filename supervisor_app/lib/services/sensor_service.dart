import 'package:firebase_database/firebase_database.dart';

import '../models/sensor_reading.dart';

/// Live IoT sensor readings from Realtime Database.
///
/// The device appends to `predictions/` as it samples. Push keys are
/// chronologically ordered, so the last child is always the newest reading.
class SensorService {
  static const String _path = 'predictions';

  final DatabaseReference _ref = FirebaseDatabase.instance.ref(_path);

  /// Streams the most recent reading, updating as the device reports.
  ///
  /// Emits null when no readings exist at all. Errors (e.g. Realtime Database
  /// rules denying access) propagate so the UI can show them rather than
  /// spinning forever.
  Stream<SensorReading?> watchLatestReading() {
    return _ref.orderByKey().limitToLast(1).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;

      // limitToLast(1) still returns a map keyed by push id.
      final entries = value.entries.toList();
      if (entries.isEmpty) return null;
      entries.sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      final latest = entries.last;

      final data = latest.value;
      if (data is! Map) return null;

      return SensorReading.fromMap(
        latest.key.toString(),
        data.map((k, v) => MapEntry(k.toString(), v)),
      );
    });
  }
}

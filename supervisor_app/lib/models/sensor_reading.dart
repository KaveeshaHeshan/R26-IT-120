/// One IoT sensor prediction from Realtime Database (`predictions/<pushKey>`).
///
/// Written by the field device after the probe is dipped. `farmer_id` and
/// `device_id` exist on the record but are not populated yet, so a reading
/// carries no reliable link to a farm — the supervisor captures it while
/// standing at the farm, and that act supplies the link.
class SensorReading {
  /// Realtime Database push key. Chronologically ordered, so the largest key
  /// is the newest reading.
  final String key;

  final String sampleId;

  /// Volatile Fatty Acid — the chemical freshness figure this whole flow
  /// exists to capture. Null when the record omits it, never defaulted.
  final double? vfa;

  final String? grade;
  final double? ph;
  final double? temperature;
  final double? turbidity;
  final DateTime? timestamp;

  const SensorReading({
    required this.key,
    required this.sampleId,
    this.vfa,
    this.grade,
    this.ph,
    this.temperature,
    this.turbidity,
    this.timestamp,
  });

  bool get hasVfa => vfa != null;

  /// How long ago the device produced this reading.
  Duration? ageFrom(DateTime now) {
    final t = timestamp;
    if (t == null) return null;
    final age = now.difference(t);
    return age.isNegative ? Duration.zero : age;
  }

  /// A reading much older than the current visit probably belongs to the
  /// previous farm. Capturing it would attach confidently wrong VFA to this
  /// collection, so the UI makes the supervisor confirm first.
  static const Duration staleAfter = Duration(minutes: 10);

  bool isStale(DateTime now) {
    final age = ageFrom(now);
    return age == null || age > staleAfter;
  }

  static double? _num(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  factory SensorReading.fromMap(String key, Map<String, dynamic> map) {
    final rawTime = map['timestamp'];
    return SensorReading(
      key: key,
      sampleId: (map['sample_id'] ?? '').toString(),
      vfa: _num(map, const ['vfa']),
      grade: (map['grade'] as Object?)?.toString(),
      // The device writes 'pH'; accept the other casings defensively.
      ph: _num(map, const ['pH', 'ph', 'PH']),
      temperature: _num(map, const ['temperature']),
      turbidity: _num(map, const ['turbidity']),
      timestamp: rawTime is String ? DateTime.tryParse(rawTime) : null,
    );
  }
}

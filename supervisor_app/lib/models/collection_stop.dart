/// One stop on a planned collection round.
///
/// Two distinct quality figures live here, and they must not be conflated:
///
///  * [spoilageScore] — 0-100, predicted by the backend Random Forest from
///    tapping metadata (hours elapsed, weather, district, experience, tree
///    condition) *before* the supervisor arrives. This is what the DQN orders
///    stops by.
///  * [vfaResult] — the chemical Volatile Fatty Acid reading taken *at the
///    farm* by the IoT sensor. Null until a sensor reports; never defaulted,
///    because a fabricated 0.0 would read as pristine latex.
class CollectionStop {
  final int order;
  final String farmerId;
  final String farmerName;
  final double latitude;
  final double longitude;

  /// 0-100 spoilage risk from the backend model.
  final double spoilageScore;

  /// Sensor-measured VFA, or null when no reading has been taken yet.
  final double? vfaResult;

  /// Quality grade, once a reading exists.
  final String? grade;

  const CollectionStop({
    required this.order,
    required this.farmerId,
    required this.farmerName,
    required this.latitude,
    required this.longitude,
    required this.spoilageScore,
    this.vfaResult,
    this.grade,
  });

  bool get hasSensorReading => vfaResult != null;

  /// Risk band derived from the spoilage score, using the same thresholds the
  /// route map colours markers by.
  String get riskLevel {
    if (spoilageScore > 60) return 'high';
    if (spoilageScore > 40) return 'medium';
    return 'safe';
  }

  factory CollectionStop.fromBackend(
    Map<String, dynamic> json, {
    String farmerName = '',
  }) {
    return CollectionStop(
      order: (json['order'] as num).toInt(),
      farmerId: json['farmer_id'] as String,
      farmerName: farmerName.isEmpty ? json['farmer_id'] as String : farmerName,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      spoilageScore: (json['spoilage_risk_score'] as num).toDouble(),
    );
  }

  CollectionStop copyWith({
    String? farmerName,
    double? vfaResult,
    String? grade,
  }) {
    return CollectionStop(
      order: order,
      farmerId: farmerId,
      farmerName: farmerName ?? this.farmerName,
      latitude: latitude,
      longitude: longitude,
      spoilageScore: spoilageScore,
      vfaResult: vfaResult ?? this.vfaResult,
      grade: grade ?? this.grade,
    );
  }
}

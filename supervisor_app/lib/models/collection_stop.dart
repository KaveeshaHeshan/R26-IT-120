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

  /// Road-adjusted distance driven from the previous stop (or the depot).
  final double? legKm;

  /// Minutes from leaving the depot until arriving here, including time
  /// spent at earlier stops.
  final int? etaMinutes;

  const CollectionStop({
    required this.order,
    required this.farmerId,
    required this.farmerName,
    required this.latitude,
    required this.longitude,
    required this.spoilageScore,
    this.vfaResult,
    this.grade,
    this.legKm,
    this.etaMinutes,
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
      legKm: (json['leg_km'] as num?)?.toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
    );
  }

  /// "1h 20m" / "45m" from [etaMinutes].
  String get etaLabel {
    final m = etaMinutes;
    if (m == null) return '—';
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
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
      legKm: legKm,
      etaMinutes: etaMinutes,
    );
  }
}

/// How the DQN's route compares with a hand-planned (nearest-neighbour) one.
class RouteEfficiency {
  final double dqnKm;
  final double baselineKm;
  final double kmSavingPct;
  final double dqnRiskExposure;
  final double baselineRiskExposure;
  final double riskSavingPct;
  final int totalMinutes;

  const RouteEfficiency({
    required this.dqnKm,
    required this.baselineKm,
    required this.kmSavingPct,
    required this.dqnRiskExposure,
    required this.baselineRiskExposure,
    required this.riskSavingPct,
    required this.totalMinutes,
  });

  /// True when the DQN drove further than the shortest tour. That is not
  /// automatically a failure — the trade is meant to be bought back in
  /// risk exposure.
  bool get drivesFurther => kmSavingPct < 0;

  /// True when the DQN loses on distance *and* on the metric it optimises,
  /// which means the policy is not fitting this geometry.
  bool get worseOnBoth => kmSavingPct < 0 && riskSavingPct < 0;

  factory RouteEfficiency.fromJson(Map<String, dynamic> j) {
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return RouteEfficiency(
      dqnKm: d('dqn_km'),
      baselineKm: d('baseline_km'),
      kmSavingPct: d('km_saving_pct'),
      dqnRiskExposure: d('dqn_risk_exposure'),
      baselineRiskExposure: d('baseline_risk_exposure'),
      riskSavingPct: d('risk_saving_pct'),
      totalMinutes: (j['total_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

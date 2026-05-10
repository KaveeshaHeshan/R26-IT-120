class Farm {
  final String farmId;
  final String farmerName;
  final double vfaResult;
  final String grade;
  final String riskLevel;
  final double lat;
  final double lng;

  Farm({
    required this.farmId,
    required this.farmerName,
    required this.vfaResult,
    required this.grade,
    required this.riskLevel,
    required this.lat,
    required this.lng,
  });

  // Convert Firestore map → Farm object
  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      farmId:     map['farm_id']     ?? '',
      farmerName: map['farmer_name'] ?? 'Unknown Farmer',
      vfaResult:  (map['vfa_result'] ?? 0.0).toDouble(),
      grade:      map['grade']       ?? '-',
      riskLevel:  map['risk_level']  ?? 'safe',
      lat:        (map['lat']        ?? 0.0).toDouble(),
      lng:        (map['lng']        ?? 0.0).toDouble(),
    );
  }
}

class LatexSession {
  final String status;
  final List<Farm> farms;
  final DateTime? updatedAt;

  LatexSession({
    required this.status,
    required this.farms,
    this.updatedAt,
  });

  factory LatexSession.fromMap(Map<String, dynamic> map) {
    final farmsData = map['farms'] as List<dynamic>? ?? [];
    final farms = farmsData
        .map((f) => Farm.fromMap(f as Map<String, dynamic>))
        .toList();

    return LatexSession(
      status:    map['status'] ?? 'idle',
      farms:     farms,
      updatedAt: map['updated_at']?.toDate(),
    );
  }

  factory LatexSession.idle() {
    return LatexSession(status: 'idle', farms: []);
  }
}
/// A tapping record submitted by a farmer, from the `tapping_details`
/// collection.
///
/// [farmerName] is not stored on the document — it is resolved separately by
/// looking up [userId] in the `users` collection.
class TappingDetail {
  final String id;
  final String userId;
  final String farmerName;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double latexVolumeL;
  final int treesCount;
  final String treeCondition;
  final String weatherCondition;
  final String notes;

  const TappingDetail({
    required this.id,
    required this.userId,
    required this.farmerName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.latexVolumeL,
    required this.treesCount,
    required this.treeCondition,
    required this.weatherCondition,
    required this.notes,
  });

  /// Average yield per tree, used as a rough quality signal on the dashboard.
  /// Returns null when the tree count is missing, rather than dividing by zero.
  double? get litresPerTree =>
      treesCount > 0 ? latexVolumeL / treesCount : null;

  factory TappingDetail.fromMap(
    String id,
    Map<String, dynamic> map, {
    String farmerName = '',
  }) {
    return TappingDetail(
      id:               id,
      userId:           map['userId'] ?? '',
      farmerName:       farmerName,
      date:             map['date']?.toDate(),
      startTime:        map['startTime'] ?? '--:--',
      endTime:          map['endTime']   ?? '--:--',
      durationMinutes:  (map['durationMinutes'] ?? 0).toInt(),
      latexVolumeL:     (map['latexVolumeL']    ?? 0).toDouble(),
      treesCount:       (map['treesCount']      ?? 0).toInt(),
      treeCondition:    map['treeCondition']    ?? 'Unknown',
      weatherCondition: map['weatherCondition'] ?? 'Unknown',
      notes:            map['notes']            ?? '',
    );
  }

  TappingDetail copyWith({String? farmerName}) {
    return TappingDetail(
      id:               id,
      userId:           userId,
      farmerName:       farmerName ?? this.farmerName,
      date:             date,
      startTime:        startTime,
      endTime:          endTime,
      durationMinutes:  durationMinutes,
      latexVolumeL:     latexVolumeL,
      treesCount:       treesCount,
      treeCondition:    treeCondition,
      weatherCondition: weatherCondition,
      notes:            notes,
    );
  }
}

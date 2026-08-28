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
  final DateTime? createdAt;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double latexVolumeL;
  final int treesCount;
  final String treeCondition;
  final String weatherCondition;
  final String notes;

  /// Farm coordinates. Null until the farmer app starts writing them — see
  /// [_readCoord] for the field shapes accepted. Deliberately nullable rather
  /// than defaulting to 0, because (0, 0) is a real point in the Atlantic and
  /// would corrupt map plotting and route distances.
  final double? lat;
  final double? lng;

  const TappingDetail({
    required this.id,
    required this.userId,
    required this.farmerName,
    required this.date,
    this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.latexVolumeL,
    required this.treesCount,
    required this.treeCondition,
    required this.weatherCondition,
    required this.notes,
    this.lat,
    this.lng,
  });

  /// Average yield per tree, used as a rough quality signal on the dashboard.
  /// Returns null when the tree count is missing, rather than dividing by zero.
  double? get litresPerTree =>
      treesCount > 0 ? latexVolumeL / treesCount : null;

  /// Whether this farm can be plotted and routed.
  bool get hasLocation => lat != null && lng != null;

  /// When tapping began, combining the `date` day with the `startTime`
  /// "HH:mm" string. Falls back to `createdAt` when either is unusable.
  DateTime? get tappingStart {
    final d = date;
    if (d == null) return createdAt;

    final parts = startTime.split(':');
    if (parts.length != 2) return createdAt ?? d;

    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return createdAt ?? d;

    return DateTime(d.year, d.month, d.day, h, m);
  }

  /// Hours elapsed since tapping began — the backend's
  /// `hours_since_tapping`. Null when no usable timestamp exists, so the
  /// caller can decide rather than sending a wrong number.
  double? hoursSinceTapping(DateTime now) {
    final start = tappingStart;
    if (start == null) return null;
    return now.difference(start).inMinutes / 60.0;
  }

  /// Reads a coordinate written by the farmer app.
  ///
  /// The live documents use `latitude`/`longitude`; `lat`/`lng` and a
  /// Firestore GeoPoint under `location` are also accepted so the reader does
  /// not break if that shape changes. Returns null when none is present,
  /// rather than a misleading 0.
  static double? _readCoord(
    Map<String, dynamic> map,
    List<String> keys,
    bool wantLatitude,
  ) {
    for (final key in keys) {
      final direct = map[key];
      if (direct is num) return direct.toDouble();
    }

    final geo = map['location'];
    if (geo != null) {
      try {
        final v = wantLatitude ? geo.latitude : geo.longitude;
        if (v is num) return v.toDouble();
      } catch (_) {
        // Not a GeoPoint — fall through.
      }
    }
    return null;
  }

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
      createdAt:        map['createdAt']?.toDate(),
      startTime:        map['startTime'] ?? '--:--',
      endTime:          map['endTime']   ?? '--:--',
      durationMinutes:  (map['durationMinutes'] ?? 0).toInt(),
      latexVolumeL:     (map['latexVolumeL']    ?? 0).toDouble(),
      treesCount:       (map['treesCount']      ?? 0).toInt(),
      treeCondition:    map['treeCondition']    ?? 'Unknown',
      weatherCondition: map['weatherCondition'] ?? 'Unknown',
      notes:            map['notes']            ?? '',
      lat:              _readCoord(map, const ['latitude', 'lat'], true),
      lng:              _readCoord(map, const ['longitude', 'lng'], false),
    );
  }

  TappingDetail copyWith({String? farmerName}) {
    return TappingDetail(
      id:               id,
      userId:           userId,
      farmerName:       farmerName ?? this.farmerName,
      date:             date,
      createdAt:        createdAt,
      startTime:        startTime,
      endTime:          endTime,
      durationMinutes:  durationMinutes,
      latexVolumeL:     latexVolumeL,
      treesCount:       treesCount,
      treeCondition:    treeCondition,
      weatherCondition: weatherCondition,
      notes:            notes,
      lat:              lat,
      lng:              lng,
    );
  }
}

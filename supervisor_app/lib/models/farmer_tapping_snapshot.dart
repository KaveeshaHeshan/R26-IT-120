import 'tapping_detail.dart';

/// One farmer from the `users` roster (role: farmer), paired with their most
/// recent tapping record.
///
/// [district] and [experience] come from the user document rather than the
/// tapping record, and [tapping] is null when the farmer has not submitted
/// one yet — the collection backend needs all of these present.
class FarmerTappingSnapshot {
  final String farmerId;
  final String userId;
  final String farmerName;
  final String district;
  final String experience;
  final TappingDetail? tapping;

  const FarmerTappingSnapshot({
    required this.farmerId,
    required this.userId,
    required this.farmerName,
    required this.district,
    required this.experience,
    this.tapping,
  });

  bool get hasFarmerId => farmerId.isNotEmpty;
  bool get hasTapping => tapping != null;

  /// Fields the spoilage model needs but that are blank for this farmer.
  ///
  /// These matter because the backend one-hot encodes categoricals and
  /// reindexes with `fill_value=0`, so an unrecognised or empty value scores
  /// as all-zeros without raising — a quietly wrong result, not an error.
  List<String> get missingFields => [
        if (district.trim().isEmpty) 'district',
        if (experience.trim().isEmpty) 'experience',
        if (!hasTapping) 'tapping record',
      ];
}

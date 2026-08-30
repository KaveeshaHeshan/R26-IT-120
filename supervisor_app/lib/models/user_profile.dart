/// Field on a `users` document holding the backend farmer id ("F001".."F012"),
/// the ids the DQN in backend/farmers.json was trained against.
///
/// Confirmed against the live database: `users` documents with role "farmer"
/// carry `modelFarmerId`. It is not `farmer_id` (no such field exists), and
/// not `userId` — that lives on `tapping_details` and holds a Firebase Auth
/// UID, not a backend farmer id.
const String kFarmerIdField = 'modelFarmerId';

/// A user record from the `users` collection.
///
/// The same shape backs both supervisors and farmers — they are told apart by
/// [role]. Supervisor records carry [employeeId]; farmer records carry the
/// land/location fields instead.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String nic;
  final String role;
  final String employeeId;

  /// Backend farmer id ("F001".."F012"), read from [kFarmerIdField] on the
  /// user document. Empty when the field is absent.
  final String farmerId;

  /// General-purpose account/display id assigned sequentially at signup
  /// ("F013", "S004", ...) — see `SignUpScreen._nextDisplayId`. This is
  /// unrelated to [farmerId] / [kFarmerIdField]: it is issued to every
  /// account, farmer or supervisor, while [farmerId] only ever exists for
  /// the 12 farmers the LSTM model was trained on. Never use [displayId] as
  /// a substitute for [farmerId] in a model request.
  final String displayId;

  /// Farmer-only profile fields, written at signup and required by the
  /// spoilage model. Empty for supervisors.
  final String district;
  final String experience;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.nic,
    required this.role,
    required this.employeeId,
    this.farmerId = '',
    this.displayId = '',
    this.district = '',
    this.experience = '',
  });

  bool get isSupervisor => role == 'supervisor';
  bool get isFarmer => role == 'farmer';

  /// First letter of the name, for the avatar badge.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid:        uid,
      name:       map['name']       ?? 'Unknown',
      email:      map['email']      ?? '',
      phone:      map['phone']      ?? '',
      nic:        map['nic']        ?? '',
      role:       map['role']       ?? '',
      employeeId: map['employeeId'] ?? '',
      farmerId:   (map[kFarmerIdField] ?? '').toString().trim(),
      displayId:  (map['displayId'] ?? '').toString().trim(),
      district:   map['district']   ?? '',
      experience: map['experience'] ?? '',
    );
  }
}

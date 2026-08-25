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

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.nic,
    required this.role,
    required this.employeeId,
  });

  bool get isSupervisor => role == 'supervisor';

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
    );
  }
}

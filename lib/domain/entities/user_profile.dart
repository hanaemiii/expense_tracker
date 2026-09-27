class UserProfile {
  UserProfile({
    this.id = 1,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  static const _unchanged = Object();

  UserProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    Object? profileImagePath = _unchanged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    profileImagePath: identical(profileImagePath, _unchanged)
        ? this.profileImagePath
        : profileImagePath as String?,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

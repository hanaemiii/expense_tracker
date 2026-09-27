import 'package:isar/isar.dart';

import '../../domain/entities/user_profile.dart';

part 'profile_record.g.dart';

@collection
class ProfileRecord {
  Id id = Isar.autoIncrement;
  late String firstName;
  late String lastName;
  late String email;
  String? profileImagePath;
  late DateTime createdAt;
  late DateTime updatedAt;

  UserProfile toEntity() => UserProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    profileImagePath: profileImagePath,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static ProfileRecord fromEntity(UserProfile profile) => ProfileRecord()
    ..id = profile.id
    ..firstName = profile.firstName
    ..lastName = profile.lastName
    ..email = profile.email
    ..profileImagePath = profile.profileImagePath
    ..createdAt = profile.createdAt
    ..updatedAt = profile.updatedAt;
}

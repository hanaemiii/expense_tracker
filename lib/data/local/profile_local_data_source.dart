import 'package:isar/isar.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/errors/validation_exception.dart';
import '../../domain/usecases/profile_actions.dart';
import '../models/profile_record.dart';

class ProfileLocalDataSource {
  ProfileLocalDataSource(this.isar);

  final Isar isar;

  Future<UserProfile> get() async {
    final existing = await isar.profileRecords.get(1);
    if (existing != null) return existing.toEntity();
    return isar.writeTxn(() async {
      final current = await isar.profileRecords.get(1);
      if (current != null) return current.toEntity();
      final profile = UserProfile(
        firstName: 'Local',
        lastName: 'User',
        email: '',
      );
      await isar.profileRecords.put(ProfileRecord.fromEntity(profile));
      return profile;
    });
  }

  Future<UserProfile> save(UserProfile profile) => isar.writeTxn(() async {
    if (profile.id != 1) {
      throw const ValidationException('Only the local profile can be edited.');
    }
    ProfileActions.validate(profile);
    final current = await isar.profileRecords.get(1);
    final saved = profile.copyWith(
      firstName: profile.firstName.trim(),
      lastName: profile.lastName.trim(),
      email: profile.email.trim(),
      createdAt: current?.createdAt ?? profile.createdAt,
      updatedAt: DateTime.now(),
    );
    await isar.profileRecords.put(ProfileRecord.fromEntity(saved));
    return saved;
  });

  Stream<UserProfile> watch() => isar.profileRecords
      .watchObject(1, fireImmediately: true)
      .asyncMap((record) async => record?.toEntity() ?? await get());
}

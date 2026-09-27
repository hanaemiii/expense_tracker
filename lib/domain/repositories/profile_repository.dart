import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> get();
  Future<UserProfile> save(UserProfile profile);
  Stream<UserProfile> watch();
}

import '../entities/user_profile.dart';
import '../errors/validation_exception.dart';
import '../repositories/profile_repository.dart';

class ProfileActions {
  ProfileActions(this.repository);

  final ProfileRepository repository;

  Future<UserProfile> get() => repository.get();

  Future<UserProfile> save(UserProfile profile) {
    validate(profile);
    return repository.save(profile);
  }

  Stream<UserProfile> watch() => repository.watch();

  static void validate(UserProfile profile) {
    if (profile.firstName.trim().isEmpty) {
      throw const ValidationException('Enter your first name.');
    }
    if (profile.lastName.trim().isEmpty) {
      throw const ValidationException('Enter your last name.');
    }
    if (profile.email.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(profile.email.trim())) {
      throw const ValidationException(
        'Enter a valid email address or leave it blank.',
      );
    }
  }
}

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/profile_local_data_source.dart';

class IsarProfileRepository implements ProfileRepository {
  IsarProfileRepository(this.source);

  final ProfileLocalDataSource source;

  @override
  Future<UserProfile> get() => source.get();

  @override
  Future<UserProfile> save(UserProfile profile) => source.save(profile);

  @override
  Stream<UserProfile> watch() => source.watch();
}

// ファイルパス: lib/features/profile/domain/repositories/profile_repository.dart

import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> fetchUserProfile();
  Future<void> updateUserProfile(UserProfile profile);
}
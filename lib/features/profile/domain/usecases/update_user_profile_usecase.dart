// ファイルパス: lib/features/profile/domain/usecases/update_user_profile_usecase.dart

import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository _repository;
  UpdateUserProfileUseCase(this._repository);

  Future<void> call(UserProfile profile) async {
    if (profile.username.trim().isEmpty) {
      throw Exception('ユーザー名は必須です。');
    }
    await _repository.updateUserProfile(profile);
  }
}
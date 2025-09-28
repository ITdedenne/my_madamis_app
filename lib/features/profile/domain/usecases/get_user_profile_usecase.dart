// ファイルパス: lib/features/profile/domain/usecases/get_user_profile_usecase.dart

import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository _repository;
  GetUserProfileUseCase(this._repository);

  Future<UserProfile> call() async {
    return await _repository.fetchUserProfile();
  }
}
// ファイルパス: lib/features/auth/domain/usecases/sign_up_usecase.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  SignUpUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    await _repository.signUp(
      email: email,
      password: password,
      username: username,
      bio: bio,
      twitterId: twitterId,
    );
  }
}
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  SignUpUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    if (email.isEmpty) {
      throw Exception('メールアドレスを入力してください');
    }
    if (password.isEmpty) {
      throw Exception('パスワードを入力してください');
    }

    await _repository.signUp(
      email: email,
      password: password,
      username: profile.username, 
    );
  }
}
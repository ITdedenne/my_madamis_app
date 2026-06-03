// ファイルパス: lib/features/auth/domain/usecases/sign_in_usecase.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;
  SignInUseCase(this._repository);

  Future<String> call(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('メールアドレスとパスワードを入力してください。');
    }
    await _repository.signIn(username: email, password: password);
    final attributes = await _repository.getCurrentUserAttributes();
    
    final usernameAttribute = attributes
        .firstWhere(
          (element) =>
              element.userAttributeKey == AuthUserAttributeKey.preferredUsername,
          // preferredUsernameがない場合、signInに使用したemailを代わりに返す
          orElse: () => AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.preferredUsername,
            value: email,
          ),
        );
        
    return usernameAttribute.value;
  }
}
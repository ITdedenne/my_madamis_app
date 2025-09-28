// ファイルパス: lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    final userAttributes = <AuthUserAttributeKey, String>{
      AuthUserAttributeKey.email: email,
      AuthUserAttributeKey.preferredUsername: username,
      if (bio != null && bio.trim().isNotEmpty)
        const CognitoUserAttributeKey.custom('bio'): bio,
      if (twitterId != null && twitterId.trim().isNotEmpty)
        const CognitoUserAttributeKey.custom('twitter_id'): twitterId,
    };

    final options = SignUpOptions(userAttributes: userAttributes);
    return await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: options,
    );
  }

  @override
  Future<SignUpResult> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    return await Amplify.Auth.confirmSignUp(
      username: username,
      confirmationCode: confirmationCode,
    );
  }

  @override
  Future<void> resendSignUpCode({required String username}) async {
    await Amplify.Auth.resendSignUpCode(username: username);
  }

  @override
  Future<SignInResult> signIn({
    required String username,
    required String password,
  }) async {
    return await Amplify.Auth.signIn(
      username: username,
      password: password,
    );
  }
  
  @override
  Future<void> signOut() async {
    // ★修正ポイント: globalSignOut を使用して、デバイス上のセッションを強制的にクリアする
    const options = SignOutOptions(globalSignOut: true);
    await Amplify.Auth.signOut(options: options);
  }
  
    @override
  Future<List<AuthUserAttribute>> getCurrentUserAttributes() async {
    try {
      return await Amplify.Auth.fetchUserAttributes();
    } catch (e) {
      rethrow;
    }
  }

    @override
  Future<void> resetPassword({required String username}) async {
    try {
      // Cognitoにリセットコードの送信をリクエスト
      await Amplify.Auth.resetPassword(username: username);
    } on AuthException catch (e) {
      safePrint('Reset password failed with error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      safePrint('An unexpected error occurred during password reset: $e');
      throw Exception('パスワードリセット中に予期せぬエラーが発生しました');
    }
  }

  @override
  Future<void> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      // リセットコードと新しいパスワードで確定処理をリクエスト
      await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on AuthException catch (e) {
      safePrint('Confirm reset password failed with error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      safePrint('An unexpected error occurred during confirm reset password: $e');
      throw Exception('パスワードの再設定中に予期せぬエラーが発生しました');
    }
  }
}
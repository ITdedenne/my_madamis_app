// ファイルパス: lib/repositories/auth_repository.dart

import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpodでこのリポジトリを提供するためのProvider
final authRepositoryProvider = Provider((_) => AuthRepository());

class AuthRepository {
  // サインアップ処理
  Future<SignUpResult> signUp({
    required String password,
    required String email,
  }) async {
    try {
 final options = SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email,
          // ユーザー名を表示名として属性に追加
          // AuthUserAttributeKey.preferredUsername: username,
        },
      );
      // Cognitoのusernameにはemailを渡す
      return await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: options,
      );
    } on AuthException {
      rethrow;
    }
  }

  // サインアップ確認処理
  Future<SignUpResult> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      return await Amplify.Auth.confirmSignUp(
        username: username,
        confirmationCode: confirmationCode,
      );
    } on AuthException {
      rethrow;
    }
  }

  // サインイン処理
  Future<SignInResult> signIn({
    required String username,
    required String password,
  }) async {
    try {
      return await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
    } on AuthException {
      rethrow;
    }
  }

  // パスワードリセット開始処理
  Future<ResetPasswordResult> resetPassword(String username) async {
    try {
      return await Amplify.Auth.resetPassword(username: username);
    } on AuthException {
      rethrow;
    }
  }

  // パスワードリセット確定処理
  Future<void> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
       await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on AuthException {
      rethrow;
    }
  }

  // サインアウト処理
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// 現在サインインしているユーザーの属性情報（ユーザー名や自己紹介など）を取得します。
  Future<Map<AuthUserAttributeKey, String>> fetchCurrentUserAttributes() async {
    try {
      final result = await Amplify.Auth.fetchUserAttributes();
      final attributes = <AuthUserAttributeKey, String>{};
      for (final attribute in result) {
        attributes[attribute.userAttributeKey] = attribute.value;
      }
      return attributes;
    } on AuthException {
      rethrow;
    }
  }

  Future<void> updateUserAttributes({
    required String username,
    required String bio,
  }) async {
    try {
      await Amplify.Auth.updateUserAttributes(
        attributes: [
          AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.preferredUsername,
            value: username,
          ),
          AuthUserAttribute(
            userAttributeKey: const CognitoUserAttributeKey.custom('bio'),
            value: bio,
          ),
        ],
      );
    } on AuthException catch (e) {
      safePrint('Error updating user attributes: $e');
      rethrow;
    }
  }
}
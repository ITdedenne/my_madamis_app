// ファイルパス: lib/features/auth/data/auth_repository.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpodでこのリポジトリを提供するためのProvider
final authRepositoryProvider = Provider((_) => AuthRepository());

class AuthRepository {
  // サインアップ処理
  Future<SignUpResult> signUp({
     required String username,
    required String password,
    required String email,
  }) async {
    try {
      final options = SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email,
           AuthUserAttributeKey.preferredUsername: username,
        },
      );
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

    // ユーザー属性の取得
  Future<List<AuthUserAttribute>> fetchUserAttributes() async {
    try {
      final result = await Amplify.Auth.fetchUserAttributes();
      return result;
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

  /// 現在サインインしているユーザーの属性情報を取得します。
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

  /// ユーザー属性（ユーザー名、自己紹介）を更新または新規作成します。
   Future<void> updateUserAttributes({
    required String username,
    required String bio,
  }) async {
    try {
      print('--- デバッグ: ユーザー名のみ更新を開始 ---');
      print('更新するユーザー名: $username');

      await Amplify.Auth.updateUserAttributes(
        attributes: [
          AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.preferredUsername,
            value: username,
          ),
        ],
      );

      print('--- デバッグ: ユーザー名のみ更新が成功 ---');

      // ユーザー名の更新が成功した場合のみ、次に自己紹介を試す
      // 自己紹介が空でなければ更新処理を行う
      if (bio.trim().isNotEmpty) {
        print('--- デバッグ: 自己紹介の更新を開始 ---');
        print('更新する自己紹介: $bio');
        await Amplify.Auth.updateUserAttributes(
          attributes: [
            AuthUserAttribute(
              userAttributeKey: const CognitoUserAttributeKey.custom('bio'),
              value: bio,
            ),
          ],
        );
        print('--- デバッグ: 自己紹介の更新が成功 ---');
      }

    } on AuthException catch (e) {
      print('属性の更新中にエラーが発生しました: $e');
      rethrow;
    }
  }
}
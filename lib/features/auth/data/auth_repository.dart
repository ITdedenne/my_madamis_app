// ファイルパス: lib/features/auth/data/auth_repository.dart

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

  /// ユーザー属性（ユーザー名、自己紹介）を更新します。
  Future<void> updateUserAttributes({
    required String username,
    required String bio,
  }) async {
    try {
      // 送信する属性のリストを準備
      final attributesToUpdate = <AuthUserAttribute>[
        // ユーザー名は必須なので必ずリストに追加
        AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.preferredUsername,
          value: username,
        ),
      ];

      // 自己紹介文が空文字やスペースだけで構成されていない場合のみ、リストに追加
      if (bio.trim().isNotEmpty) {
        attributesToUpdate.add(
          AuthUserAttribute(
            userAttributeKey: const CognitoUserAttributeKey.custom('bio'),
            value: bio,
          ),
        );
      }

      // 準備したリストを使って属性を更新
      await Amplify.Auth.updateUserAttributes(
        attributes: attributesToUpdate,
      );
    } on AuthException catch (e) {
      // safePrintはAmplifyライブラリの機能なので、
      // どこでも使えるように標準のprintに変更するか、別途インポートが必要です。
      // ここでは標準のprintを使用します。
      print('Error updating user attributes: $e');
      rethrow;
    }
  }
}
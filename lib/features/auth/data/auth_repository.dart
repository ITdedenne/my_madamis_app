// ファイルパス: lib/features/auth/data/auth_repository.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());

class AuthRepository {
  Future<SignUpResult> signUpWithProfile({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    try {
      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.email: email,
        AuthUserAttributeKey.preferredUsername: username,
      };
      if (bio != null && bio.trim().isNotEmpty) {
        userAttributes[const CognitoUserAttributeKey.custom('bio')] = bio;
      }
      if (twitterId != null && twitterId.trim().isNotEmpty) {
        userAttributes[const CognitoUserAttributeKey.custom('twitter_id')] = twitterId;
      }

      final options = SignUpOptions(
        userAttributes: userAttributes,
      );
      return await Amplify.Auth.signUp(
        username: email, // Cognitoのusernameはemailを使用
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
  /// ユーザー属性を更新します。
  /// bioやtwitterIdがnullや空文字の場合は更新しません。
  Future<void> updateUserAttributes({
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    try {
      final attributesToUpdate = [
        AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.preferredUsername,
          value: username,
        ),
      ];

      // bioがnullや空でなければ属性リストに追加
      if (bio != null && bio.trim().isNotEmpty) {
        attributesToUpdate.add(AuthUserAttribute(
          userAttributeKey: const CognitoUserAttributeKey.custom('bio'),
          value: bio,
        ));
      }

      // twitterIdがnullや空でなければ属性リストに追加
      if (twitterId != null && twitterId.trim().isNotEmpty) {
        attributesToUpdate.add(AuthUserAttribute(
          userAttributeKey: const CognitoUserAttributeKey.custom('twitter_id'),
          value: twitterId,
        ));
      }
      
      await Amplify.Auth.updateUserAttributes(attributes: attributesToUpdate);
    } on AuthException catch (e) {
      safePrint('属性の更新中にエラーが発生しました: $e');
      rethrow;
    }
  }
}
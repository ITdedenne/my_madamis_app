// ファイルパス: lib/features/settings/data/repositories/settings_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<void> updateEmail(String newEmail) async {
    await Amplify.Auth.updateUserAttribute(
      userAttributeKey: AuthUserAttributeKey.email,
      value: newEmail,
    );
  }

  @override
  Future<void> confirmUpdateEmail(String confirmationCode) async {
    await Amplify.Auth.confirmUserAttribute(
      userAttributeKey: AuthUserAttributeKey.email,
      confirmationCode: confirmationCode,
    );
  }

  @override
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Amplify.Auth.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAccount() async {
    const mutation = r'''
      mutation DeleteUserAccount {
        deleteUserAccount
      }
    ''';

    final request = GraphQLRequest<String>(
      document: mutation,
    );

    try {
      final response = await Amplify.API.mutate(request: request).response;
      
      if (response.hasErrors) {
        throw Exception('GraphQL Errors: ${response.errors.map((e) => e.message).join(', ')}');
      }
      
      // 成功した場合、ローカルセッションも破棄する
      await Amplify.Auth.signOut();
      
    } catch (e) {
      safePrint('Error deleting account: $e');
      rethrow;
    }
  }
}
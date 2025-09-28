// ファイルパス: lib/features/settings/data/repositories/settings_repository_impl.dart

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
}
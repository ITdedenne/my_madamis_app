// ファイルパス: lib/features/settings/domain/repositories/settings_repository.dart

abstract class SettingsRepository {
  Future<void> updateEmail(String newEmail);
  Future<void> confirmUpdateEmail(String confirmationCode);
  Future<void> updatePassword({required String oldPassword, required String newPassword});
  
  /// ユーザーアカウントを削除する (退会)
  Future<void> deleteAccount();
}
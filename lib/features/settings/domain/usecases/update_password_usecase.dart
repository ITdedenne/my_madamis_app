// ファイルパス: lib/features/settings/domain/usecases/update_password_usecase.dart

import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

class UpdatePasswordUseCase {
  final SettingsRepository _repository;
  UpdatePasswordUseCase(this._repository);

  Future<void> call({required String oldPassword, required String newPassword}) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('パスワードを入力してください。');
    }
    if (newPassword.length < 8) {
      throw Exception('新しいパスワードは8文字以上である必要があります。');
    }
    await _repository.updatePassword(oldPassword: oldPassword, newPassword: newPassword);
  }
}
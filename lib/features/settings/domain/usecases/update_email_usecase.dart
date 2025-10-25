// ファイルパス: lib/features/settings/domain/usecases/update_email_usecase.dart

import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

class UpdateEmailUseCase {
  final SettingsRepository _repository;
  UpdateEmailUseCase(this._repository);

  Future<void> call(String newEmail) async {
    // Basic validation
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      throw Exception('有効なメールアドレスを入力してください。');
    }
    await _repository.updateEmail(newEmail);
  }
}
// ファイルパス: lib/features/settings/domain/usecases/confirm_update_email_usecase.dart

import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';



class ConfirmUpdateEmailUseCase {
  final SettingsRepository _repository;
  ConfirmUpdateEmailUseCase(this._repository);

  Future<void> call(String confirmationCode) async {
    if (confirmationCode.isEmpty) {
      throw Exception('確認コードを入力してください。');
    }
    await _repository.confirmUpdateEmail(confirmationCode);
  }
}
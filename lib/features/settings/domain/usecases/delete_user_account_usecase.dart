// ファイルパス: lib/features/settings/domain/usecases/delete_user_account_usecase.dart

import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';

class DeleteUserAccountUseCase {
  final SettingsRepository _repository;
  DeleteUserAccountUseCase(this._repository);

  Future<void> call() async {
    await _repository.deleteAccount();
  }
}
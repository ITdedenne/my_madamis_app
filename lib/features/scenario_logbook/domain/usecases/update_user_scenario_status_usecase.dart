// lib/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

// クラス名を UpdateUserScenarioStatusUseCase (Cを大文字) にします
class UpdateUserScenarioStatusUseCase {
  final ScenarioRepository _repository;
  UpdateUserScenarioStatusUseCase(this._repository);

  // call メソッドの引数を ViewModel から渡される形に修正
  Future<void> call({
    required String userId,
    required String scenarioId,
    required bool isPlayed,
    required bool isPossessed,
  }) {
    // リポジトリの新しいメソッドを呼び出すように修正
    return _repository.updateUserScenarioStatus(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: isPlayed,
      isPossessed: isPossessed,
    );
  }
}
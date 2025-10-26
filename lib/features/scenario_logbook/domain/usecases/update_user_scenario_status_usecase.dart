// ファイルパス: lib/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart'; 

class UpdateUserScenarioStatusUseCase {
  final ScenarioRepository _repository;
  final UserScenarioStatusNotifier _notifier; 

  UpdateUserScenarioStatusUseCase(this._repository, this._notifier);

  Future<void> call(String scenarioId, UserScenarioStatus newStatus) async {
    // 1. DBの更新を実行 (removeまたはupdate)
    if (newStatus.isUnregistered) {
      await _repository.removeUserScenarioStatus(scenarioId);
    } else {
      await _repository.updateUserScenarioStatus(scenarioId, newStatus);
    }

    // 2. DB更新成功後、グローバルステート（Notifier）を更新
    _notifier.updateStatus(scenarioId, newStatus);
  }
}
// Provider定義は lib/providers.dart に移動したため、このファイルからは削除
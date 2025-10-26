// ファイルパス: lib/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart'; // ★追加

class UpdateUserScenarioStatusUseCase {
  final ScenarioRepository _repository;
  final UserScenarioStatusNotifier _notifier; // ★追加: Notifierを直接参照

  UpdateUserScenarioStatusUseCase(this._repository, this._notifier);

  Future<void> call(String scenarioId, UserScenarioStatus newStatus) async {
    // 1. DBの更新を実行 (removeまたはupdate)
    if (newStatus.isUnregistered) {
      await _repository.removeUserScenarioStatus(scenarioId);
    } else {
      await _repository.updateUserScenarioStatus(scenarioId, newStatus);
    }

    // 2. ★追加: DB更新成功後、グローバルステート（Notifier）を更新
    // これにより、探す画面のアイコンとマイリスト画面が即座に更新される
    _notifier.updateStatus(scenarioId, newStatus);
  }
}
// Provider定義は lib/providers.dart に移動したため、ここでは不要
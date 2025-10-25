import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

class UpdateUserScenarioStatusUseCase {
  final ScenarioRepository _repository;
  UpdateUserScenarioStatusUseCase(this._repository);

  Future<void> call(String scenarioId, UserScenarioStatus newStatus) {
    if (newStatus.isUnregistered) {
      return _repository.removeUserScenarioStatus(scenarioId);
    } else {
      return _repository.updateUserScenarioStatus(scenarioId, newStatus);
    }
  }
}
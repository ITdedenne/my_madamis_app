// ファイルパス: lib/features/scenario_logbook/domain/usecases/get_user_scenarios_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

class GetUserScenariosUseCase {
  final ScenarioRepository _repository;
  GetUserScenariosUseCase(this._repository);

  Future<List<UserScenario>> call(String userId) {
    return _repository.fetchUserScenarios(userId);
  }
}
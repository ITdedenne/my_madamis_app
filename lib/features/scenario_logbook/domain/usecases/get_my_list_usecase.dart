import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

class GetMyListUseCase {
  final ScenarioRepository _repository;
  GetMyListUseCase(this._repository);

  Future<List<UserScenario>> call() {
    return _repository.fetchMyList();
  }
}
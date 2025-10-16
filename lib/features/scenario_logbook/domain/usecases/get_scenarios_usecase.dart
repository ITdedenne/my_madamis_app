import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

class GetScenariosUseCase {
  final ScenarioRepository _repository;
  GetScenariosUseCase(this._repository);

  Future<List<Scenario>> call({required int page, int limit = 50, String? searchTerm}) {
    return _repository.fetchScenarios(page: page, limit: limit, searchTerm: searchTerm);
  }
}
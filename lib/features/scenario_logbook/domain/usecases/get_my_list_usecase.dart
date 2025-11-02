// lib/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class GetMyListUsecase {
  final ScenarioRepository repository;

  GetMyListUsecase(this.repository);

  Future<List<ScenarioLogbookEntry>> call(String userId) {
    return repository.getMyScenarioLogbook(userId);
  }
}
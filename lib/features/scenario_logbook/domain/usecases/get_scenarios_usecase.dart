// lib/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class GetScenariosUsecase {
  final ScenarioRepository repository;

  GetScenariosUsecase(this.repository);

  Future<ScenarioWithMyStatusConnection> call({
    required String userId,
    Map<String, dynamic>? filter,
    int? limit,
    String? nextToken,
  }) {
    return repository.listScenariosWithMyStatus(
      userId: userId,
      filter: filter,
      limit: limit,
      nextToken: nextToken,
    );
  }
}
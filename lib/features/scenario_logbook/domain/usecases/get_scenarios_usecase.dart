// ファイルパス: lib/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

class GetScenariosUseCase {
  final ScenarioRepository _repository;
  GetScenariosUseCase(this._repository);

  Future<List<Scenario>> call({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
  }) {
    return _repository.fetchScenarios(
      page: page,
      limit: limit,
      searchTerm: searchTerm,
      playerCountRange: playerCountRange,
      gmRequirement: gmRequirement,
    );
  }
}
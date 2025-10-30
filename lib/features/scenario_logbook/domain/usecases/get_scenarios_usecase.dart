// ファイルパス: lib/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart
// 内容: 【修正】

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

import '../entities/scenario_page.dart';

class GetScenariosUseCase {
  final ScenarioRepository _repository;
  GetScenariosUseCase(this._repository);

  Future<ScenarioPage> call({ // ★戻り値を ScenarioPage に変更
    String? nextToken, // ★ page から nextToken に変更
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) {
    return _repository.fetchScenarios(
      nextToken: nextToken, // ★変更
      limit: limit,
      searchTerm: searchTerm,
      playerCountRange: playerCountRange,
      gmRequirement: gmRequirement,
      authorName: authorName,
    );
  }
}
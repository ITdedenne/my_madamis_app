// ファイルパス: lib/features/scenario_logbook/domain/repositories/scenario_repository.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

abstract class ScenarioRepository {
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  });

  Future<List<String>> fetchAllAuthorNames();

  Future<List<UserScenario>> fetchMyList();

  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status);

  Future<void> removeUserScenarioStatus(String scenarioId);
}
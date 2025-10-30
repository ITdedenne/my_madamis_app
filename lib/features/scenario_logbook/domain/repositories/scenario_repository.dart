// ファイルパス: lib/features/scenario_logbook/domain/repositories/scenario_repository.dart
// 内容: 【修正】

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

import '../entities/scenario_page.dart';

// ★追加

abstract class ScenarioRepository {
  Future<ScenarioPage> fetchScenarios({ // ★戻り値を ScenarioPage に変更
    String? nextToken, // ★ page から nextToken に変更
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
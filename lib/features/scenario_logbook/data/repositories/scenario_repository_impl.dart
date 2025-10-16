// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  static const int _totalScenarios = 175;
  late final List<Scenario> _allScenarios;

  ScenarioRepositoryImpl() {
    _allScenarios = List.generate(_totalScenarios, (index) {
      final id = index + 1;
      return Scenario(
        id: 'scenario_$id',
        title: 'シナリオ No.$id',
        authorName: '作者 ${(id % 10) + 1}',
        minPlayerCount: (id % 4) + 3,
        maxPlayerCount: (id % 4) + 5,
        gmRequirement: GmRequirement.values[id % 3],
      );
    });
  }

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    Iterable<Scenario> scenarios = _allScenarios;

    if (searchTerm != null && searchTerm.isNotEmpty) {
      scenarios = scenarios.where((s) =>
          s.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          s.authorName.toLowerCase().contains(searchTerm.toLowerCase()));
    }
    if (authorName != null && authorName.isNotEmpty) {
      scenarios = scenarios.where((s) => s.authorName == authorName);
    }
    if (gmRequirement != null) {
      scenarios = scenarios.where((s) => s.gmRequirement == gmRequirement);
    }
    if (playerCountRange != null) {
      scenarios = scenarios.where((s) {
        final start = playerCountRange.start.round();
        final end = playerCountRange.end.round();
        return s.minPlayerCount >= start && s.maxPlayerCount <= end;
      });
    }
    
    final filteredList = scenarios.toList();
    
    final startIndex = (page - 1) * limit;
    if (startIndex >= filteredList.length) return [];
    final endIndex = (startIndex + limit > filteredList.length) ? filteredList.length : startIndex + limit;

    return filteredList.sublist(startIndex, endIndex);
  }

  @override
  Future<List<String>> fetchAllAuthorNames() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _allScenarios.map((s) => s.authorName).toSet().toList();
  }

  @override
  Future<List<UserScenario>> fetchMyList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const UserScenario(
        scenario: Scenario(id: 'scenario_1', title: '通過済みのシナリオ', authorName: '作者A', minPlayerCount: 4, maxPlayerCount: 4, gmRequirement: GmRequirement.required),
        status: UserScenarioStatus(isPlayed: true),
      ),
      const UserScenario(
        scenario: Scenario(id: 'scenario_5', title: '所持しているシナリオ', authorName: '作者B', minPlayerCount: 5, maxPlayerCount: 5, gmRequirement: GmRequirement.none),
        status: UserScenarioStatus(isPossessed: true),
      ),
      const UserScenario(
        scenario: Scenario(id: 'scenario_8', title: '通過済みかつ所持', authorName: '作者C', minPlayerCount: 6, maxPlayerCount: 6, gmRequirement: GmRequirement.optional),
        status: UserScenarioStatus(isPlayed: true, isPossessed: true),
      ),
    ];
  }

  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
    print('Updating $scenarioId to isPlayed: ${status.isPlayed}, isPossessed: ${status.isPossessed}');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    print('Removing $scenarioId');
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
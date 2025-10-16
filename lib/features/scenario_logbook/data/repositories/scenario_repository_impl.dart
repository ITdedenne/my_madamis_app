// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  static const int _totalScenarios = 175;
  late final List<Scenario> _allScenarios;

  // ユーザーのステータスを保持するインメモリの偽データベース
  final Map<String, UserScenarioStatus> _userStatuses = {};

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
    // 初期データの設定
    _userStatuses['scenario_1'] = const UserScenarioStatus(isPlayed: true);
    _userStatuses['scenario_5'] = const UserScenarioStatus(isPossessed: true);
    _userStatuses['scenario_8'] = const UserScenarioStatus(isPlayed: true, isPossessed: true);
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
    await Future.delayed(const Duration(milliseconds: 100));
    return _userStatuses.entries.map((entry) {
      final scenario = _allScenarios.firstWhere((s) => s.id == entry.key);
      return UserScenario(scenario: scenario, status: entry.value);
    }).toList();
  }

  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (status.isUnregistered) {
      _userStatuses.remove(scenarioId);
    } else {
      _userStatuses[scenarioId] = status;
    }
    print('Updated Statuses: $_userStatuses');
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _userStatuses.remove(scenarioId);
    print('Removed Statuses: $_userStatuses');
  }
}
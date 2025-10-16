// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  static const int _totalScenarios = 175;
  late final List<Scenario> _allScenarios;

  // Repository初期化時に全ダミーデータを生成
  ScenarioRepositoryImpl() {
    _allScenarios = List.generate(_totalScenarios, (index) {
      final id = index + 1;
      return Scenario(
        id: 'scenario_$id',
        title: 'シナリオ No.$id',
        authorName: '作者 ${(id % 10) + 1}',
        minPlayerCount: (id % 4) + 3, // 3-6人で変動
        maxPlayerCount: (id % 4) + 5, // 5-8人で変動
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

    // --- 絞り込みと検索処理 ---
    Iterable<Scenario> scenarios = _allScenarios;

    // 検索語（シナリオ名 or 作者名）
    if (searchTerm != null && searchTerm.isNotEmpty) {
      scenarios = scenarios.where((s) =>
          s.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          s.authorName.toLowerCase().contains(searchTerm.toLowerCase()));
    }
    // 作者名（絞り込み）
    if (authorName != null && authorName.isNotEmpty) {
      scenarios = scenarios.where((s) => s.authorName == authorName);
    }
    // GM要否
    if (gmRequirement != null) {
      scenarios = scenarios.where((s) => s.gmRequirement == gmRequirement);
    }
    // プレイ人数
    if (playerCountRange != null) {
      scenarios = scenarios.where((s) {
        final start = playerCountRange.start.round();
        final end = playerCountRange.end.round();
        return s.minPlayerCount >= start && s.maxPlayerCount <= end;
      });
    }
    
    final filteredList = scenarios.toList();
    
    // --- ページネーション処理 ---
    final startIndex = (page - 1) * limit;
    if (startIndex >= filteredList.length) {
      return []; // そのページにはデータがない
    }
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
    // _allScenariosからダミーのマイリストデータを生成
    return [
      UserScenario(
        scenario: _allScenarios[0], // シナリオ No.1
        status: const UserScenarioStatus(isPlayed: true),
      ),
      UserScenario(
        scenario: _allScenarios[4], // シナリオ No.5
        status: const UserScenarioStatus(isPossessed: true),
      ),
      UserScenario(
        scenario: _allScenarios[7], // シナリオ No.8
        status: const UserScenarioStatus(isPlayed: true, isPossessed: true),
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
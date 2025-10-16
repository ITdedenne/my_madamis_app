// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  // ダミーデータの総数を定義
  static const int _totalScenarios = 175;

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 【変更点①】4ページまでデータが存在するように変更 (175件 / 50件/ページ = 3.5 -> 4ページ)
    final totalPages = (_totalScenarios / limit).ceil();
    if (page > totalPages) {
      return [];
    }

    // 取得するシナリオの数を計算（最終ページ対応）
    final startIndex = (page - 1) * limit;
    final count = (startIndex + limit > _totalScenarios) ? (_totalScenarios - startIndex) : limit;

    return List.generate(count, (index) {
      final id = startIndex + index + 1;
      return Scenario(
        id: 'scenario_$id',
        title: 'シナリオ No.$id ${searchTerm != null && searchTerm.isNotEmpty ? ' (検索結果: $searchTerm)' : ''}',
        authorName: '作者 $id',
        minPlayerCount: (id % 4) + 3,
        maxPlayerCount: (id % 4) + 5,
        gmRequirement: GmRequirement.values[id % 3],
      );
    });
  }
  
  // 【変更点②】statusの型を新しいクラスに合わせる
  @override
  Future<List<UserScenario>> fetchMyList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const UserScenario(
        scenario: Scenario(id: 'scenario_1', title: '通過済みのシナリオ', authorName: '作者A', minPlayerCount: 4, maxPlayerCount: 4, gmRequirement: GmRequirement.required),
        status: UserScenarioStatus(isPlayed: true), // isPlayed: true
      ),
      const UserScenario(
        scenario: Scenario(id: 'scenario_5', title: '所持しているシナリオ', authorName: '作者B', minPlayerCount: 5, maxPlayerCount: 5, gmRequirement: GmRequirement.none),
        status: UserScenarioStatus(isPossessed: true), // isPossessed: true
      ),
      const UserScenario(
        scenario: Scenario(id: 'scenario_8', title: '通過済みかつ所持', authorName: '作者C', minPlayerCount: 6, maxPlayerCount: 6, gmRequirement: GmRequirement.optional),
        status: UserScenarioStatus(isPlayed: true, isPossessed: true), // 両方true
      ),
    ];
  }

  // 【変更点③】引数の型を新しいクラスに合わせる
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
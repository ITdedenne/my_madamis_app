// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 4ページ目以降はデータがないものとして空リストを返す
    if (page > 3) {
      return [];
    }

    // ページ番号とインデックスに基づいてIDを計算
    return List.generate(limit, (index) {
      final id = (page - 1) * limit + index + 1; 
      return Scenario(
        id: 'scenario_$id',
        title: 'シナリオ No.$id ${searchTerm != null && searchTerm.isNotEmpty ? ' (検索結果: $searchTerm)' : ''}',
        authorName: '作者 $id',
        minPlayerCount: (id % 4) + 3, // 3-6人で変動
        maxPlayerCount: (id % 4) + 5, // 5-8人で変動
        gmRequirement: GmRequirement.values[id % 3], // Enumを循環させる
      );
    });
  }

  // ▼▼▼ 以下3つのメソッドの実装を追加 ▼▼▼

  @override
  Future<List<UserScenario>> fetchMyList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // ダミーのマイリストデータ
    return [
      const UserScenario(
        scenario: Scenario(id: 'scenario_1', title: '通過済みのシナリオ', authorName: '作者A', minPlayerCount: 4, maxPlayerCount: 4, gmRequirement: GmRequirement.required),
        status: UserScenarioStatus.played,
      ),
      const UserScenario(
        scenario: Scenario(id: 'scenario_5', title: '所持しているシナリオ', authorName: '作者B', minPlayerCount: 5, maxPlayerCount: 5, gmRequirement: GmRequirement.none),
        status: UserScenarioStatus.possessed,
      ),
    ];
  }

  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
    // NOTE: ここでAmplify経由でDynamoDBのUserScenarioテーブルにデータを保存/更新します。
    print('Updating $scenarioId to $status');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    // NOTE: ここでAmplify経由でDynamoDBのUserScenarioテーブルからデータを削除します。
    print('Removing $scenarioId');
    await Future.delayed(const Duration(milliseconds: 200));
  }
  // ▲▲▲ 修正ここまで ▲▲▲
}
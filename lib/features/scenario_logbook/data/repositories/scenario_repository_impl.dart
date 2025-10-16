// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

import '../../domain/repositories/scenario_repository.dart';

// Repositoryのインターフェースを実装するクラス
class ScenarioRepositoryImpl implements ScenarioRepository {
  
  // NOTE: ここにAmplify/DynamoDBとの通信ロジックを実装します。
  // 今回はダミーデータを返すことでUIの動作確認を可能にします。

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
  }) async {
    // 擬似的な待機時間
    await Future.delayed(const Duration(milliseconds: 500));

    // ダミーデータ生成
    return List.generate(limit, (index) {
      final id = (page - 1) * limit + index + 1;
      return Scenario(
        id: 'scenario_$id',
        title: 'シナリオ No.$id ${searchTerm ?? ''}',
        authorName: '作者 $id',
        minPlayerCount: 3,
        maxPlayerCount: 5,
        gmRequirement: GmRequirement.optional,
      );
    });
  }

  @override
  Future<List<UserScenario>> fetchMyList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // ダミーのマイリストデータ
    return [
     const UserScenario(
        scenario:  Scenario(id: 'scenario_1', title: '通過済みのシナリオ', authorName: '作者A', minPlayerCount: 4, maxPlayerCount: 4, gmRequirement: GmRequirement.required),
        status: UserScenarioStatus.played,
      ),
     const  UserScenario(
        scenario:  Scenario(id: 'scenario_5', title: '所持しているシナリオ', authorName: '作者B', minPlayerCount: 5, maxPlayerCount: 5, gmRequirement: GmRequirement.none),
        status: UserScenarioStatus.possessed,
      ),
    ];
  }

  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
    // Amplify経由でDynamoDBのUserScenarioテーブルにデータを保存/更新する
    print('Updating $scenarioId to $status');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    // Amplify経由でDynamoDBのUserScenarioテーブルからデータを削除する
    print('Removing $scenarioId');
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
// lib/features/scenario_logbook/domain/repositories/scenario_repository.dart

import 'package:my_madamis_app/models/ModelProvider.dart';

abstract class ScenarioRepository {
  /// [探す] 画面用: 全シナリオとユーザーステータスを取得 (Req 1.4.2)
  /// BE側でフィルタリング・ページネーションを行う
  // --- ▼ 修正 ▼ ---
  // スキーマ(schema.graphql)に合わせて userId を削除
  Future<ScenarioWithMyStatusConnection> listScenariosWithMyStatus({
    Map<String, dynamic>? filter,
    int? limit, // GQLでは使わないが、VM->RepoのI/Fとして残す
    String? nextToken,
  });
  // --- ▲ 修正 ▲ ---

  /// [マイリスト] 画面用: ユーザーのログブックを取得 (Req 1.4.1)
  /// フィルタリングはFE側で行う
  Future<List<ScenarioLogbookEntry>> getMyScenarioLogbook(String userId);

  /// ステータス更新 (Req 1.2.4)
  Future<void> updateUserScenarioStatus({
    required String userId,
    required String scenarioId,
    bool isPlayed,
    bool isPossessed,
  });
}
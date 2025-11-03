// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert' as model_helpers; // jsonEncode のために import
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/graphql/custom_queries.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'dart:developer'; // logを使用するために import

class ScenarioRepositoryImpl implements ScenarioRepository {
  /// [探す] 画面用: BEのカスタムクエリを叩く
  @override
  // --- ▼ 修正 ▼ ---
  // I/F 変更に合わせて userId を削除
  Future<ScenarioWithMyStatusConnection> listScenariosWithMyStatus({
    Map<String, dynamic>? filter,
    int? limit, // (※ GQL呼び出しでは使用しない)
    String? nextToken,
  }) async {
  // --- ▲ 修正 ▲ ---
    try {
      // --- ▼ 修正 ▼ ---
      // filter (Map) を JSON文字列にエンコードする (TypeMismatchエラー対応)
      final filterString =
          (filter != null && filter.isNotEmpty) ? model_helpers.jsonEncode(filter) : null;
      
      final request = GraphQLRequest<String>(
        document: listScenariosWithMyStatusQuery,
        // GQLクエリ(custom_queries.dart)の引数に合わせる
        variables: <String, dynamic>{
          // 'userId': userId, // UnknownArgumentエラーのため削除
          if (filterString != null) 'filter': filterString,
          // if (limit != null) 'limit': limit, // UnknownArgumentエラーのため削除
          if (nextToken != null) 'nextToken': nextToken,
          // 'sort' 引数もスキーマにはあるが、一旦 null を渡す (必要ならI/Fに追加)
          'sort': null, 
        },
      );
      // --- ▲ 修正 ▲ ---

      final response = await Amplify.API.query(request: request).response;
      final responseData = response.data;

      if (responseData == null || response.hasErrors) {
        log('Error fetching scenarios: ${response.errors}');
        throw Exception(
            'Failed to list scenarios with status: ${response.errors}');
      }

      final jsonMap =
          model_helpers.jsonDecode(responseData) as Map<String, dynamic>; 
      final connectionData =
          jsonMap['listScenariosWithMyStatus'] as Map<String, dynamic>;

      return ScenarioWithMyStatusConnection.fromJson(connectionData);
    } catch (e) {
      log('GraphQL Error: $e');
      throw Exception('Failed to execute listScenariosWithMyStatus: $e');
    }
  }

  /// [マイリスト] 画面用: BEのカスタムクエリを叩く
  @override
  Future<List<ScenarioLogbookEntry>> getMyScenarioLogbook(String userId) async {
    // (変更なし。userId を引数に取るが、GQL呼び出しで使っていないのでエラーにならない)
    try {
      final request = GraphQLRequest<String>(
        document: getMyScenarioLogbookQuery,
        variables: {}, // 引数なし
      );

      final response = await Amplify.API.query(request: request).response;
      final responseData = response.data;

      if (responseData == null || response.hasErrors) {
        log('Error fetching logbook: ${response.errors}');
        throw Exception('Failed to get scenario logbook: ${response.errors}');
      }

      final jsonMap =
          model_helpers.jsonDecode(responseData) as Map<String, dynamic>;
      final itemsData = jsonMap['getMyScenarioLogbook'] as List;

      return itemsData
          .map((item) =>
              ScenarioLogbookEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('GraphQL Error: $e');
      throw Exception('Failed to execute getMyScenarioLogbook: $e');
    }
  }

  /// [書き込み処理] ステータス更新
  @override
  Future<void> updateUserScenarioStatus({
    // (変更なし)
    required String userId,
    required String scenarioId,
    bool isPlayed = false,
    bool isPossessed = false,
  }) async {
    try {
      // 既存のレコードを検索
      // --- ▼ 修正: USER/SCENARIO ではなく、IDフィールド (USERID/SCENARIOID) で検索する ▼ ---
      final existingEntries = await Amplify.DataStore.query(
        UserScenario.classType,
        where: UserScenario.USERID
            .eq(userId)
            .and(UserScenario.SCENARIOID.eq(scenarioId)), 
      );
      // --- ▲ 修正 ▲ ---

      final existingEntry =
          existingEntries.isNotEmpty ? existingEntries.first : null;

      if (isPlayed == false && isPossessed == false) {
        // 両方 false なら「未登録」= レコードを削除
        if (existingEntry != null) {
          await Amplify.DataStore.delete(existingEntry);
        }
      } else {
        // どちらかが true なら「登録」= レコードを作成または更新
        if (existingEntry != null) {
          // 更新
          final updatedEntry = existingEntry.copyWith(
            isPlayed: isPlayed,
            isPossessed: isPossessed,
          );
          await Amplify.DataStore.save(updatedEntry);
        } else {
          // --- 【新規作成】 ---
          // IDから親オブジェクトを取得する
          final userQuery = await Amplify.DataStore.query(
            User.classType,
            where: User.ID.eq(userId),
          );
          final scenarioQuery = await Amplify.DataStore.query(
            Scenario.classType,
            where: Scenario.ID.eq(scenarioId),
          );

          if (userQuery.isEmpty || scenarioQuery.isEmpty) {
            throw Exception('User or Scenario not found for creating relation');
          }

          final userObject = userQuery.first;
          final scenarioObject = scenarioQuery.first;

          // 正しいコンストラクタ引数で作成
          final newEntry = UserScenario(
            user: userObject,
            scenario: scenarioObject,
            isPlayed: isPlayed,
            isPossessed: isPossessed,
          );
          await Amplify.DataStore.save(newEntry);
        }
      }
    } catch (e) {
      log('Error updating user scenario status: $e');
      throw Exception('Failed to update status: $e');
    }
  }
}
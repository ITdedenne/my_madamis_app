// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert' as model_helpers;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/graphql/custom_queries.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'dart:developer';

class ScenarioRepositoryImpl implements ScenarioRepository {
  /// [探す] 画面用: BEのカスタムクエリを叩く
  @override
  Future<ScenarioWithMyStatusConnection> listScenariosWithMyStatus({
    Map<String, dynamic>? filter,
    int? limit,
    String? nextToken,
  }) async {
    try {
      final filterString =
          (filter != null && filter.isNotEmpty) ? model_helpers.jsonEncode(filter) : null;
      
      final request = GraphQLRequest<String>(
        document: listScenariosWithMyStatusQuery,
        variables: <String, dynamic>{
          if (filterString != null) 'filter': filterString,
          if (nextToken != null) 'nextToken': nextToken,
          'sort': null, 
        },
      );

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
    try {
      final request = GraphQLRequest<String>(
        document: getMyScenarioLogbookQuery,
        variables: {},
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
    required String userId,
    required String scenarioId,
    bool isPlayed = false,
    bool isPossessed = false,
  }) async {
    try {
      // 既存のレコードを検索（前回の修正で問題解決済み）
      final existingEntries = await Amplify.DataStore.query(
        UserScenario.classType,
        where: UserScenario.USERID
            .eq(userId)
            .and(UserScenario.SCENARIOID.eq(scenarioId)), 
      );

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
          
          // ▼▼▼ 修正: Userモデルの主キー(username)で検索する ▼▼▼
          final userQuery = await Amplify.DataStore.query(
            User.classType,
            where: User.USERNAME.eq(userId), // <--- IDではなくUSERNAMEで検索
          );
          // ▲▲▲ 修正 ▲▲▲
          
          // Scenarioオブジェクトの取得（Scenarioの主キーはIDなのでこのままでOK）
          final scenarioQuery = await Amplify.DataStore.query(
            Scenario.classType,
            where: Scenario.ID.eq(scenarioId),
          );

          if (userQuery.isEmpty || scenarioQuery.isEmpty) {
            log('User ID: $userId, Scenario ID: $scenarioId');
            throw Exception('User or Scenario not found for creating relation');
          }

          final userObject = userQuery.first;
          final scenarioObject = scenarioQuery.first;

          // 新しいレコードを作成して保存
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
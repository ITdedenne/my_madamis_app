// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert' as ModelHelpers;

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/graphql/custom_queries.dart'; 
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'dart:developer'; // logを使用するために import

class ScenarioRepositoryImpl implements ScenarioRepository {
  /// [探す] 画面用: BEのカスタムクエリを叩く
  @override
  Future<ScenarioWithMyStatusConnection> listScenariosWithMyStatus({
    required String userId,
    Map<String, dynamic>? filter,
    int? limit,
    String? nextToken,
  }) async {
    try {
      final request = GraphQLRequest<String>(
        document: listScenariosWithMyStatusQuery,
        variables: <String, dynamic>{
          'userId': userId,
          if (filter != null) 'filter': filter,
          if (limit != null) 'limit': limit,
          if (nextToken != null) 'nextToken': nextToken,
        },
      );

      final response = await Amplify.API.query(request: request).response;
      final responseData = response.data;

      if (responseData == null || response.hasErrors) {
        log('Error fetching scenarios: ${response.errors}');
        throw Exception('Failed to list scenarios with status: ${response.errors}');
      }

      final jsonMap = ModelHelpers.jsonDecode(responseData) as Map<String, dynamic>;
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
      );

      final response = await Amplify.API.query(request: request).response;
      final responseData = response.data;

      if (responseData == null || response.hasErrors) {
        log('Error fetching logbook: ${response.errors}');
        throw Exception('Failed to get scenario logbook: ${response.errors}');
      }
      
      final jsonMap = ModelHelpers.jsonDecode(responseData) as Map<String, dynamic>;
      final itemsData =
          jsonMap['getMyScenarioLogbook'] as List;

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
      // 既存のレコードを検索
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
          // 新規作成
          final newEntry = UserScenario(
            userId: userId,
            scenarioId: scenarioId,
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
// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert' as model_helpers; 
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/graphql/custom_queries.dart';
import 'package:my_madamis_app/graphql/custom_mutations.dart'; // <--- 追加
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
      // ▼▼▼ 修正: DataStore操作からLambda関数によるカスタムMutation呼び出しに切り替え ▼▼▼
      final request = GraphQLRequest<String>(
        document: updateUserScenarioStatusMutation, // <--- カスタムMutationを使用
        variables: <String, dynamic>{
          'userId': userId,
          'scenarioId': scenarioId,
          'isPlayed': isPlayed,
          'isPossessed': isPossessed,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      
      if (response.hasErrors) {
        log('Error updating status via Lambda: ${response.errors}');
        throw Exception('Failed to update status via Lambda: ${response.errors}');
      }
      
    } catch (e) {
      log('Error executing updateUserScenarioStatus: $e');
      throw Exception('Failed to execute update status mutation: $e');
    }
  }
}
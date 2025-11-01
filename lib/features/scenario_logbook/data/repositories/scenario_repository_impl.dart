// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart
// 内容: 【修正】

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart'; // RangeValuesのために必要
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

// ScenarioPage のインポート (変更なし)
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario_page.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  ScenarioRepositoryImpl() {
    // コンストラクタ
  }

  // --- _getCurrentUserId (変更なし) ---
  Future<String> _getCurrentUserId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      // CognitoのUser ID (sub) を取得
      return attributes
          .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.sub) 
          .value;
    } on Exception catch (e) {
       safePrint('Failed to get current userId: $e');
       throw Exception('Authentication required to access user data.');
    }
  }

  // ★★★ _findExistingUserScenario を修正 (listUserScenarios -> byUser) ★★★
  Future<amplify_models.UserScenario?> _findExistingUserScenario(String userId, String scenarioId) async {
      
      // クエリを GSI (byUser) を使うように変更
      const queryDoc = r'''
        query ByUser($userId: ID!, $scenarioId: ModelIDKeyConditionInput, $limit: Int) {
          byUser(userId: $userId, scenarioId: $scenarioId, limit: $limit) {
            items {
              id
              status
            }
          }
        }
      ''';

      final queryRequest = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
          document: queryDoc, // ★ 変更
          modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
          variables: {
              'userId': userId, // ★ GSIのPK
              'scenarioId': { 'eq': scenarioId }, // ★ GSIのSK (ソートキー)
              'limit': 1, // 1件のみ取得
          },
          decodePath: 'byUser', // ★ 変更
          authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: queryRequest).response;

      // エラーもしくはデータが無い場合は null を返す (変更なし)
      if (response.data == null || response.data!.items.isEmpty || response.hasErrors) {
          return null;
      }
      return response.data!.items.firstOrNull;
  }
  // ---

  // --- fetchScenarios (変更なし・Null安全対応とPagination対応は適用済み) ---
  @override
  Future<ScenarioPage> fetchScenarios({
    String? nextToken, 
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    try {
      // フィルターロジック (変更なし)
      final Map<String, dynamic> filter = {};
      final List<Map<String, dynamic>> orConditions = [];
      if (searchTerm != null && searchTerm.isNotEmpty) {
        orConditions.add({
          'title': {'contains': searchTerm}
        });
      }
      if (gmRequirement != null) {
        filter['gmRequirement'] = {'eq': gmRequirement.toGraphQLString()};
      }
      if (playerCountRange != null) {
        final start = playerCountRange.start.round();
        final end = playerCountRange.end.round();
        filter['minPlayerCount'] = {'le': end};
        filter['maxPlayerCount'] = {'ge': start};
      }
      if (orConditions.isNotEmpty) {
        filter['or'] = orConditions;
      }
      final Map<String, dynamic> queryVariables = {
        'limit': limit,
        'nextToken': nextToken,
      };
      if (filter.isNotEmpty) {
        queryVariables['filter'] = filter;
      }

      // クエリリクエスト (変更なし)
      final request = GraphQLRequest<PaginatedResult<amplify_models.Scenario>>(
        document: '''
          query ListScenarios(\$filter: ModelScenarioFilterInput, \$limit: Int, \$nextToken: String) {
            listScenarios(filter: \$filter, limit: \$limit, nextToken: \$nextToken) {
              items {
                id
                title
                minPlayerCount
                maxPlayerCount
                gmRequirement
                storeUrl
                author {
                  id
                  authorName
                }
              }
              nextToken
            }
          }
        ''',
        modelType: const PaginatedModelType(amplify_models.Scenario.classType),
        variables: queryVariables, 
        decodePath: 'listScenarios', 
        authorizationMode: APIAuthorizationType.userPools, 
      );

      safePrint('Executing GraphQL Query with variables: ${request.variables}');

      final response = await Amplify.API.query(request: request).response;
      final data = response.data;

      if (data == null || response.hasErrors) {
        safePrint('GraphQL Errors: ${response.errors}');
        throw Exception('Failed to fetch scenarios: ${response.errors}');
      }

      // データ変換 (Null安全対応済み)
      List<Scenario> scenarios = data.items
          .where((scenarioModel) => scenarioModel != null)
          .map((scenarioModel) {
              final authorNameStr = scenarioModel!.author?.authorName ?? ' (作者不明)';
              final titleStr = scenarioModel.title ?? ' (タイトルなし)';
              
              return Scenario.fromModel(scenarioModel, authorNameStr, titleStr);
            })
          .toList();

      // クライアントサイドフィルタ (変更なし)
      if (authorName != null && authorName.isNotEmpty) {
        scenarios = scenarios.where((s) => s.authorName == authorName).toList();
      }
      if (searchTerm != null && searchTerm.isNotEmpty) {
         scenarios = scenarios.where((s) => 
           s.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
           s.authorName.toLowerCase().contains(searchTerm.toLowerCase())
         ).toList();
      }

      // 戻り値 (変更なし)
      return ScenarioPage(
        scenarios: scenarios,
        nextToken: data.nextToken, 
      );

    } on ApiException catch (e) {
      safePrint('Failed to fetch scenarios: ${e.message}');
      throw Exception('Failed to fetch scenarios: ${e.message}');
    } catch (e) {
      safePrint('An unexpected error occurred in fetchScenarios: $e');
      rethrow; 
    }
  }

  // --- fetchAllAuthorNames (変更なし・Null安全対応とAuth対応は適用済み) ---
  @override
  Future<List<String>> fetchAllAuthorNames() async {
     try {
       const graphQLDocument = '''
         query ListAuthors(\$limit: Int) {
           listAuthors(limit: \$limit) {
             items {
               authorName
             }
           }
         }
       ''';

      final request = GraphQLRequest<PaginatedResult<amplify_models.Author>>(
         document: graphQLDocument,
         modelType: const PaginatedModelType(amplify_models.Author.classType),
         variables: {'limit': 1000},
         decodePath: 'listAuthors',
         authorizationMode: APIAuthorizationType.userPools,
      );

       final response = await Amplify.API.query(request: request).response;
       final data = response.data;

       if (data == null || response.hasErrors) {
         safePrint('GraphQL Errors fetching authors: ${response.errors}');
         throw Exception('Failed to fetch authors: ${response.errors}');
       }

       return data.items
           // Null安全対応
           .where((author) => author != null && author.authorName != null && author.authorName!.isNotEmpty)
           .map((author) => author!.authorName!)
           .toSet()
           .toList()
           ..sort();

     } on ApiException catch (e) {
       safePrint('Failed to fetch author names: ${e.message}');
       throw Exception('Failed to fetch author names: ${e.message}');
     } catch (e) {
       safePrint('An unexpected error occurred fetching author names: $e');
       rethrow;
     }
  }
  
  // ★★★ fetchMyList を修正 (listUserScenarios -> byUser) ★★★
  @override
  Future<List<UserScenario>> fetchMyList() async {
    final userId = await _getCurrentUserId();

    // GSI (byUser) をクエリするGraphQLクエリに変更
    const graphQLDocument = '''
      query ByUser(\$userId: ID!, \$limit: Int) {
        byUser(userId: \$userId, limit: \$limit) {
          items {
            id
            status
            scenario {
              id
              title
              minPlayerCount
              maxPlayerCount
              gmRequirement
              storeUrl
              author {
                authorName
              }
            }
          }
        }
      }
    ''';

    final request = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
      document: graphQLDocument, // ★ 変更
      modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
      variables: {
        'userId': userId, // ★ filter ではなく、GSIのPKを直接指定
        'limit': 2000, // ひとまず最大件数を指定（必要に応じてページネーション実装）
      },
      decodePath: 'byUser', // ★ 変更
      authorizationMode: APIAuthorizationType.userPools, 
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.data == null || response.hasErrors) {
      safePrint('GraphQL Errors fetching myList (byUser): ${response.errors}'); // ★ ログ変更
      throw Exception('Failed to fetch my list: ${response.errors}');
    }

    try {
      // データ変換処理 (Null安全対応は適用済み)
      return response.data!.items
        .whereType<amplify_models.UserScenario>()
        .where((us) => us.scenario != null) 
        .map((us) {
          final scenarioModel = us.scenario!;
          final authorNameStr = scenarioModel.author?.authorName ?? ' (作者不明)';
          final titleStr = scenarioModel.title ?? ' (タイトルなし)';
          
          final scenarioEntity = Scenario.fromModel(
            scenarioModel, 
            authorNameStr,
            titleStr,
          );
          
          final statusStr = us.status ?? ''; 

          return UserScenario(
            scenario: scenarioEntity,
            status: UserScenarioStatus.fromString(statusStr),
          );
        }).toList();
    } catch (e) {
        safePrint('Error mapping fetchMyList results: $e');
        // Null安全対応でクラッシュはしなくなったはずだが、念のため残す
        throw Exception('Failed to process user scenario data: $e');
    }
  }

  // --- updateUserScenarioStatus (変更なし) ---
  // (内部で呼ぶ _findExistingUserScenario が修正されたため、この関数は変更不要)
  @override
  Future<void> updateUserScenarioStatus(
      String scenarioId, UserScenarioStatus status) async {
    final userId = await _getCurrentUserId();
    final statusString = status.toStringValue();

    if (status.isUnregistered) {
      await removeUserScenarioStatus(scenarioId);
      return;
    }
    
    final existing = await _findExistingUserScenario(userId, scenarioId);

    if (existing != null) {
      const updateDoc = r'''
        mutation UpdateUserScenario($input: UpdateUserScenarioInput!) {
          updateUserScenario(input: $input) {
            id
            status
          }
        }
      ''';
      
      final updateRequest = GraphQLRequest<amplify_models.UserScenario>(
        document: updateDoc,
        modelType: amplify_models.UserScenario.classType,
        variables: {
          'input': {
            'id': existing.id, 
            'status': statusString,
          }
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: updateRequest).response;
      if (response.hasErrors) {
          safePrint('GraphQL Error updating UserScenario: ${response.errors}');
          throw Exception('Failed to update user scenario status: ${response.errors}');
      }
      safePrint('Updated UserScenario for $scenarioId to $statusString (ID: ${existing.id})');
      
    } else {
      const createDoc = r'''
        mutation CreateUserScenario($input: CreateUserScenarioInput!) {
          createUserScenario(input: $input) {
            id
            userId
            scenarioId
            status
          }
        }
      ''';
      
      final newId =  UUID.getUUID();

      final createRequest = GraphQLRequest<amplify_models.UserScenario>(
        document: createDoc,
        modelType: amplify_models.UserScenario.classType,
        variables: {
          'input': {
            'id': newId,
            'userId': userId, 
            'scenarioId': scenarioId, 
            'status': statusString,
          }
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: createRequest).response;
      if (response.hasErrors) {
          safePrint('GraphQL Error creating UserScenario: ${response.errors}');
          throw Exception('Failed to create user scenario status: ${response.errors}');
      }
      safePrint('Created new UserScenario for $scenarioId with status $statusString (ID: $newId)');
    }
  }

  // --- removeUserScenarioStatus (変更なし) ---
  // (内部で呼ぶ _findExistingUserScenario が修正されたため、この関数は変更不要)
  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    final userId = await _getCurrentUserId();

    final existing = await _findExistingUserScenario(userId, scenarioId);

    if (existing != null) {
      const deleteDoc = r'''
        mutation DeleteUserScenario($input: DeleteUserScenarioInput!) {
          deleteUserScenario(input: $input) {
            id
          }
        }
      ''';

      final deleteRequest = GraphQLRequest<amplify_models.UserScenario>(
        document: deleteDoc,
        modelType: amplify_models.UserScenario.classType,
        variables: {
          'input': {
            'id': existing.id, 
          }
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: deleteRequest).response;
      if (response.hasErrors) {
          safePrint('GraphQL Error deleting UserScenario: ${response.errors}');
          throw Exception('Failed to delete user scenario status: ${response.errors}');
      }
      safePrint('Removed UserScenario for $scenarioId (ID: ${existing.id})');
    } else {
      safePrint('UserScenario for $scenarioId not found, nothing to remove.');
    }
  }
}
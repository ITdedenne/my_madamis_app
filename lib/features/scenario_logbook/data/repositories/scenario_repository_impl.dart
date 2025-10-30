// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart
// 内容: 【修正】

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart'; // RangeValuesのために必要
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

// ★追加
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario_page.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  ScenarioRepositoryImpl() {
    // コンストラクタ
  }

  // --- _getCurrentUserId と _findExistingUserScenario は変更なし ---
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

  Future<amplify_models.UserScenario?> _findExistingUserScenario(String userId, String scenarioId) async {
      const queryDoc = r'''
        query ListUserScenarios($filter: ModelUserScenarioFilterInput, $limit: Int) {
          listUserScenarios(filter: $filter, limit: $limit) {
            items {
              id
              status
            }
          }
        }
      ''';

      final queryRequest = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
          document: queryDoc,
          modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
          variables: {
              'filter': {
                  'userId': {'eq': userId},
                  'scenarioId': {'eq': scenarioId},
              },
              'limit': 1, // 1件のみ取得
          },
          decodePath: 'listUserScenarios',
          authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: queryRequest).response;

      if (response.data == null || response.data!.items.isEmpty || response.hasErrors) {
          return null;
      }
      return response.data!.items.firstOrNull;
  }
  // ---

  // ★★★ fetchScenarios を修正 ★★★
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
      // 1. GraphQLクエリの準備 (フィルターロジックは変更なし)
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

      // GraphQLリクエストの作成 (クエリ自体は変更なし)
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
        // ★★★ 修正点 ★★★
        // authorizationMode: APIAuthorizationType.apiKey, // 古い設定
        authorizationMode: APIAuthorizationType.userPools, // ★ ログインユーザーの権限(Cognito)で実行
      );

      safePrint('Executing GraphQL Query with variables: ${request.variables}');

      final response = await Amplify.API.query(request: request).response;
      final data = response.data;

      if (data == null || response.hasErrors) {
        safePrint('GraphQL Errors: ${response.errors}');
        throw Exception('Failed to fetch scenarios: ${response.errors}');
      }

      // 2. 取得したAmplifyモデルをドメインエンティティに変換
      List<Scenario> scenarios = data.items
          .where((scenarioModel) => scenarioModel != null)
          .map((scenarioModel) {
              final authorNameStr = scenarioModel!.author?.authorName ?? '';
              return Scenario.fromModel(scenarioModel, authorNameStr);
            })
          .toList();

      // クライアントサイドでのフィルタリング (変更なし)
      if (authorName != null && authorName.isNotEmpty) {
        scenarios = scenarios.where((s) => s.authorName == authorName).toList();
      }

      if (searchTerm != null && searchTerm.isNotEmpty) {
         scenarios = scenarios.where((s) => 
           s.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
           s.authorName.toLowerCase().contains(searchTerm.toLowerCase())
         ).toList();
      }

      // 3. ScenarioPage でラップして返す
      return ScenarioPage(
        scenarios: scenarios,
        nextToken: data.nextToken, 
      );

    } on ApiException catch (e) {
      safePrint('Failed to fetch scenarios: ${e.message}');
      throw Exception('Failed to fetch scenarios: ${e.message}');
    } catch (e) {
      safePrint('An unexpected error occurred: $e');
      rethrow;
    }
  }

  // ★★★ fetchAllAuthorNames を修正 ★★★
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
         // ★★★ 修正点 ★★★
         // authorizationMode: APIAuthorizationType.apiKey, // 古い設定
         authorizationMode: APIAuthorizationType.userPools, // ★ ログインユーザーの権限(Cognito)で実行
      );

       final response = await Amplify.API.query(request: request).response;
       final data = response.data;

       if (data == null || response.hasErrors) {
         safePrint('GraphQL Errors fetching authors: ${response.errors}');
         throw Exception('Failed to fetch authors: ${response.errors}');
       }

       return data.items
           .where((author) => author != null && author.authorName.isNotEmpty)
           .map((author) => author!.authorName)
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
  
  // --- fetchMyList, updateUserScenarioStatus, removeUserScenarioStatus は変更なし ---
  // (これらは元から userPools を使っていたため問題ありません)
  
  @override
  Future<List<UserScenario>> fetchMyList() async {
    final userId = await _getCurrentUserId();

    final request = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
      document: '''
        query ListUserScenarios(\$filter: ModelUserScenarioFilterInput, \$limit: Int) {
          listUserScenarios(filter: \$filter, limit: \$limit) {
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
      ''',
      modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
      variables: {
        'filter': {
          'userId': {'eq': userId}, 
        },
        'limit': 2000, 
      },
      decodePath: 'listUserScenarios',
      authorizationMode: APIAuthorizationType.userPools, 
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.data == null || response.hasErrors) {
      safePrint('GraphQL Errors fetching myList: ${response.errors}');
      throw Exception('Failed to fetch my list: ${response.errors}');
    }

    return response.data!.items
      .whereType<amplify_models.UserScenario>()
      .where((us) => us.scenario != null) 
      .map((us) {
        final scenarioModel = us.scenario!;
        final scenarioEntity = Scenario.fromModel(
          scenarioModel, 
          scenarioModel.author?.authorName ?? '',
        );
        return UserScenario(
          scenario: scenarioEntity,
          status: UserScenarioStatus.fromString(us.status),
        );
      }).toList();
  }

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
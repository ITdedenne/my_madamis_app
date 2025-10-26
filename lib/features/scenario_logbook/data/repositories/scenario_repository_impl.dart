// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart'; // RangeValuesのために必要
// amplify_modelsへのエイリアスはそのまま
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull のために必要

class ScenarioRepositoryImpl implements ScenarioRepository {

  // --- fetchScenarios と fetchAllAuthorNames は変更なし ---
  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    // ... (変更なし) ...
    try {
      final Map<String, dynamic> filter = {};
      final List<Map<String, dynamic>> andConditions = []; // AND条件用

      // 検索語 (タイトル)
      if (searchTerm != null && searchTerm.isNotEmpty) {
         filter['title'] = {'contains': searchTerm.toLowerCase()};
      }

      // GM要否
      if (gmRequirement != null) {
        andConditions.add({'gmRequirement': {'eq': gmRequirement.toGraphQLString()}});
      }

      // プレイ人数
      if (playerCountRange != null) {
        final start = playerCountRange.start.round();
        final end = playerCountRange.end.round();
        andConditions.add({'minPlayerCount': {'le': end}});
        andConditions.add({'maxPlayerCount': {'ge': start}});
      }

      // 作者名
      if (authorName != null && authorName.isNotEmpty) {
         andConditions.add({
           'author': {
              'authorName': {'eq': authorName}
           }
         });
      }

      if (andConditions.isNotEmpty) {
        filter['and'] = andConditions;
      }

      final Map<String, dynamic> effectiveFilter = filter.isEmpty ? {} : {'filter': filter};

      final Map<String, dynamic> queryVariables = {
        'limit': limit,
        ...effectiveFilter,
      };

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
        authorizationMode: APIAuthorizationType.apiKey,
      );

      safePrint('Executing ListScenarios GraphQL Query with variables: ${request.variables}');
      final response = await Amplify.API.query(request: request).response;
      final data = response.data;

      if (data == null || response.hasErrors) {
        safePrint('GraphQL Errors fetching scenarios: ${response.errors}');
        throw Exception('Failed to fetch scenarios: ${response.errors}');
      }

      final scenarios = data.items
          .whereType<amplify_models.Scenario>()
          .map((scenarioModel) {
              final authorNameStr = scenarioModel.author?.authorName ?? '';
              return Scenario.fromModel(scenarioModel, authorNameStr);
            })
          .toList();

      return scenarios;

    } on ApiException catch (e) {
      safePrint('Failed to fetch scenarios: ${e.message}');
      throw Exception('Failed to fetch scenarios: ${e.message}');
    } catch (e) {
      safePrint('An unexpected error occurred during fetchScenarios: $e');
      rethrow;
    }
  }


  @override
  Future<List<String>> fetchAllAuthorNames() async {
     // ... (変更なし) ...
     try {
       const graphQLDocument = '''
         query ListAuthors(\$limit: Int, \$nextToken: String) {
           listAuthors(limit: \$limit, nextToken: \$nextToken) {
             items {
               authorName
             }
             nextToken
           }
         }
       ''';

       List<String> allNames = [];
       String? nextToken;

       do {
          final request = GraphQLRequest<PaginatedResult<amplify_models.Author>>(
             document: graphQLDocument,
             modelType: const PaginatedModelType(amplify_models.Author.classType),
             variables: {'limit': 1000, 'nextToken': nextToken},
             decodePath: 'listAuthors',
             authorizationMode: APIAuthorizationType.apiKey,
          );

          final response = await Amplify.API.query(request: request).response;
          final data = response.data;

          if (data == null || response.hasErrors) {
             safePrint('GraphQL Errors fetching authors: ${response.errors}');
             throw Exception('Failed to fetch authors: ${response.errors}');
          }

          final names = data.items
             .whereType<amplify_models.Author>()
             .where((author) => author.authorName.isNotEmpty)
             .map((author) => author.authorName);
          allNames.addAll(names);
          nextToken = data.nextToken;

       } while (nextToken != null);

       return allNames.toSet().toList()..sort();

     } on ApiException catch (e) {
       safePrint('Failed to fetch author names: ${e.message}');
       throw Exception('Failed to fetch author names: ${e.message}');
     } catch (e) {
       safePrint('An unexpected error occurred fetching author names: $e');
       rethrow;
     }
  }

  // --- UserScenario関連のメソッド ---

  Future<String> _getCurrentUserId() async {
    try {
      final currentUser = await Amplify.Auth.getCurrentUser();
      return currentUser.userId;
    } on AuthException catch (e) {
      safePrint("Could not get current user ID: ${e.message}");
      throw Exception("ログインしているユーザーが見つかりません。");
    }
  }

  String _statusToString(UserScenarioStatus status) {
    if (status.isPlayed && status.isPossessed) return "played_possessed";
    if (status.isPlayed) return "played";
    if (status.isPossessed) return "possessed";
    return "none";
  }

  UserScenarioStatus _stringToStatus(String statusStr) {
    bool isPlayed = statusStr.contains("played");
    bool isPossessed = statusStr.contains("possessed");
    return UserScenarioStatus(isPlayed: isPlayed, isPossessed: isPossessed);
  }

  @override
  Future<List<UserScenario>> fetchMyList() async {
    try {
      final userId = await _getCurrentUserId();

       // ★★★ 修正: クエリ名を userScenariosByUserId に修正 ★★★
       const graphQLDocument = '''
         query UserScenariosByUserId(\$userId: ID!, \$limit: Int, \$nextToken: String) {
           userScenariosByUserId(userId: \$userId, limit: \$limit, nextToken: \$nextToken) {
             items {
               id
               userId
               scenarioId
               status
               scenario {
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
             }
             nextToken
           }
         }
       ''';

      List<amplify_models.UserScenario> allUserScenarios = [];
      String? nextToken;

      do {
          final request = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
            document: graphQLDocument,
            modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
            variables: {'userId': userId, 'limit': 100, 'nextToken': nextToken},
            // ★★★ 修正: decodePath も userScenariosByUserId に修正 ★★★
            decodePath: 'userScenariosByUserId',
            authorizationMode: APIAuthorizationType.userPools,
          );

          safePrint('Executing userScenariosByUserId GraphQL Query with variables: ${request.variables}');

          final response = await Amplify.API.query(request: request).response;
          final data = response.data;

          if (data == null || response.hasErrors) {
            safePrint('GraphQL Errors fetching user scenarios: ${response.errors}');
            // エラーの詳細を投げるように変更
            throw Exception('Failed to fetch user scenarios: ${response.errors}');
          }

          allUserScenarios.addAll(data.items.whereType<amplify_models.UserScenario>());
          nextToken = data.nextToken;

      } while (nextToken != null);

      final result = allUserScenarios
          .map((userScenarioModel) {
            final scenarioModel = userScenarioModel.scenario;
            if (scenarioModel == null) {
              safePrint("Warning: UserScenario ${userScenarioModel.id} has no associated Scenario data.");
              return null;
            }
            final authorName = scenarioModel.author?.authorName ?? '';
            final scenario = Scenario.fromModel(scenarioModel, authorName);
            final status = _stringToStatus(userScenarioModel.status);
            return UserScenario(scenario: scenario, status: status);
          })
          .whereType<UserScenario>()
          .toList();

       safePrint("Fetched ${result.length} items for MyList for user $userId");
       return result;

    } on ApiException catch (e) {
      safePrint('Failed to fetch MyList: ${e.message}');
      throw Exception('マイリストの取得に失敗しました: ${e.message}');
    } catch (e) {
       safePrint('An unexpected error occurred during fetchMyList: $e');
      rethrow; // 元の例外を再スロー
    }
  }

  // --- updateUserScenarioStatus と removeUserScenarioStatus は変更なし ---
  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
     // ... (変更なし) ...
     try {
       final userId = await _getCurrentUserId();
       final statusString = _statusToString(status);

       final existingEntry = await _findUserScenarioEntry(userId, scenarioId);

       if (existingEntry == null) {
         // --- 新規作成 ---
          const createMutation = '''
            mutation CreateUserScenario(\$input: CreateUserScenarioInput!) {
              createUserScenario(input: \$input) {
                id
                userId
                scenarioId
                status
                createdAt
                updatedAt
              }
            }
          ''';
          final input = {
             'userId': userId,
             'scenarioId': scenarioId,
             'status': statusString,
          };

          final request = GraphQLRequest<amplify_models.UserScenario>(
            document: createMutation,
            modelType: amplify_models.UserScenario.classType,
            variables: {'input': input},
            decodePath: 'createUserScenario',
            authorizationMode: APIAuthorizationType.userPools,
          );

         safePrint('Creating UserScenario with input: $input');
         final response = await Amplify.API.mutate(request: request).response;

         final createdItem = response.data;
         if (createdItem == null || response.hasErrors) {
           safePrint('Failed to create UserScenario: ${response.errors}');
           throw Exception('シナリオステータスの作成に失敗しました: ${response.errors}');
         }
         safePrint('Successfully created UserScenario: ${createdItem.id}');

       } else {
         // --- 更新 ---
          const updateMutation = '''
            mutation UpdateUserScenario(\$input: UpdateUserScenarioInput!) {
              updateUserScenario(input: \$input) {
                 id
                 userId
                 scenarioId
                 status
                 createdAt
                 updatedAt
              }
            }
          ''';
          final input = {
             'id': existingEntry.id, // ★ 必須
             'status': statusString,
          };

          final request = GraphQLRequest<amplify_models.UserScenario>(
             document: updateMutation,
             modelType: amplify_models.UserScenario.classType,
             variables: {'input': input},
             decodePath: 'updateUserScenario',
             authorizationMode: APIAuthorizationType.userPools,
          );

         safePrint('Updating UserScenario: id=${existingEntry.id}, status=$statusString, input=$input');
         final response = await Amplify.API.mutate(request: request).response;

          final updatedItem = response.data;
         if (updatedItem == null || response.hasErrors) {
           safePrint('Failed to update UserScenario: ${response.errors}');
           throw Exception('シナリオステータスの更新に失敗しました: ${response.errors}');
         }
         safePrint('Successfully updated UserScenario: ${updatedItem.id}');
       }

     } on ApiException catch (e) {
       safePrint('Failed to update user scenario status: ${e.message}');
       throw Exception('シナリオステータスの更新に失敗しました: ${e.message}');
     } catch (e) {
       safePrint('An unexpected error occurred during updateUserScenarioStatus: $e');
       rethrow;
     }
  }

   @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
      // ... (変更なし) ...
     try {
       final userId = await _getCurrentUserId();
       final entryToDelete = await _findUserScenarioEntry(userId, scenarioId);

       if (entryToDelete != null) {
          const deleteMutation = '''
            mutation DeleteUserScenario(\$input: DeleteUserScenarioInput!) {
              deleteUserScenario(input: \$input) {
                id
              }
            }
          ''';
          final input = {
             'id': entryToDelete.id, // ★ 必須
          };

          final request = GraphQLRequest<amplify_models.UserScenario>(
             document: deleteMutation,
             modelType: amplify_models.UserScenario.classType,
             variables: {'input': input},
             decodePath: 'deleteUserScenario',
             authorizationMode: APIAuthorizationType.userPools,
          );

          safePrint('Deleting UserScenario: id=${entryToDelete.id}, input=$input');
          final response = await Amplify.API.mutate(request: request).response;

         final deletedItem = response.data;
         if (response.hasErrors) {
            safePrint('Failed to delete UserScenario: ${response.errors}');
            throw Exception('シナリオステータスの削除に失敗しました: ${response.errors}');
         } else if (deletedItem != null) {
            safePrint('Successfully deleted UserScenario: ${deletedItem.id}');
         } else {
            safePrint('Successfully initiated deletion for UserScenario: ${entryToDelete.id} (response data was null)');
         }
       } else {
         safePrint('UserScenario not found for deletion: userId=$userId, scenarioId=$scenarioId. Assuming already removed.');
       }
     } on ApiException catch (e) {
       safePrint('Failed to remove user scenario status: ${e.message}');
       throw Exception('シナリオステータスの削除に失敗しました: ${e.message}');
     } catch (e) {
       safePrint('An unexpected error occurred during removeUserScenarioStatus: $e');
       rethrow;
     }
  }


   /// userId と scenarioId で UserScenario を検索するヘルパー関数
   Future<amplify_models.UserScenario?> _findUserScenarioEntry(String userId, String scenarioId) async {
      // ★★★ 修正: クエリ名を userScenariosByUserId に修正 ★★★
      const graphQLDocument = '''
        query UserScenariosByUserIdAndScenarioId(\$userId: ID!, \$scenarioId: ModelIDKeyConditionInput) {
          userScenariosByUserId(userId: \$userId, scenarioId: \$scenarioId, limit: 1) {
            items {
              id
              userId
              scenarioId
              status
              createdAt
              updatedAt
            }
            nextToken
          }
        }
      ''';
      final scenarioIdCondition = {'eq': scenarioId};

     final request = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
        document: graphQLDocument,
        modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
        variables: {
          'userId': userId,
          'scenarioId': scenarioIdCondition,
        },
        // ★★★ 修正: decodePath も userScenariosByUserId に修正 ★★★
        decodePath: 'userScenariosByUserId',
        authorizationMode: APIAuthorizationType.userPools,
     );

     safePrint('Executing query to find existing UserScenario with variables: ${request.variables}');
      final response = await Amplify.API.query(request: request).response;
      final data = response.data;

      if (data == null || response.hasErrors) {
        safePrint('GraphQL Errors finding user scenario: ${response.errors}');
        return null; // 見つからなかった扱い
      }

      final items = data.items.whereType<amplify_models.UserScenario>().toList();
      safePrint('Found ${items.length} existing UserScenario entries.');
      return items.firstOrNull;
   }
}
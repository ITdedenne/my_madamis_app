// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart'; // ModelMutationsとGraphQLRequestを明確に参照
import 'package:flutter/material.dart'; // RangeValuesのために必要
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  ScenarioRepositoryImpl() {
    // コンストラクタ内のダミーデータ生成ロジックを削除しました。
  }

  // --- 共通ヘルパー関数: 現在認証済みのユーザーIDを取得 ---
  Future<String> _getCurrentUserId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return attributes
          .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.sub) // ★修正: userId -> sub (CognitoのユーザーID)
          .value;
    } on Exception catch (e) {
       safePrint('Failed to get current userId: $e');
       throw Exception('Authentication required to access user data.');
    }
  }

  // ヘルパー関数: UserScenarioをFilterで検索 (userIdとscenarioIdで検索し、既存レコードのidを取得)
  Future<amplify_models.UserScenario?> _findExistingUserScenario(String userId, String scenarioId) async {
      // DynamoDBのGSI (byUserまたはbyScenario) に対応するGraphQLフィルタを使用
      const queryDoc = r'''
        query ListUserScenarios($filter: ModelUserScenarioFilterInput, $limit: Int) {
          listUserScenarios(filter: $filter, limit: $limit) {
            items {
              id
              status
              # userId, scenarioIdはリゾルバが解決するため、ここでは不要だが、フィルタ変数で必要
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

      // ★修正: Amplify.API.queryの引数はnamed parameterのrequestのみ
      final response = await Amplify.API.query(request: queryRequest).response;

      if (response.data == null || response.data!.items.isEmpty || response.hasErrors) {
          return null;
      }
      return response.data!.items.firstOrNull;
  }

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    // ... (前回の回答のfetchScenariosメソッドはそのまま。修正不要) ...
    try {
      // 1. GraphQLクエリの準備 (既存のロジックを維持)
      final Map<String, dynamic> filter = {};
      final List<Map<String, dynamic>> orConditions = [];

      // 検索語 (タイトル or 作者名)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        orConditions.add({
          'title': {'contains': searchTerm}
        });
      }

      // GM要否
      if (gmRequirement != null) {
        filter['gmRequirement'] = {'eq': gmRequirement.toGraphQLString()};
      }

      // プレイ人数
      if (playerCountRange != null) {
        final start = playerCountRange.start.round();
        final end = playerCountRange.end.round();
        
        filter['minPlayerCount'] = {'le': end};
        filter['maxPlayerCount'] = {'ge': start};
      }

      // 'or' 条件を追加
      if (orConditions.isNotEmpty) {
        filter['or'] = orConditions;
      }

      // ページネーションを考慮
      final offset = (page - 1) * limit;

      final Map<String, dynamic> queryVariables = {
        'limit': limit,
        'nextToken': page > 1 ? _calculateNextToken(offset) : null,
      };
      if (filter.isNotEmpty) {
        queryVariables['filter'] = filter;
      }

      // GraphQLリクエストの作成
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

      // クライアントサイドでのフィルタリング
      if (authorName != null && authorName.isNotEmpty) {
        scenarios = scenarios.where((s) => s.authorName == authorName).toList();
      }

      if (searchTerm != null && searchTerm.isNotEmpty) {
         scenarios = scenarios.where((s) => 
           s.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
           s.authorName.toLowerCase().contains(searchTerm.toLowerCase())
         ).toList();
      }

      return scenarios;

    } on ApiException catch (e) {
      safePrint('Failed to fetch scenarios: ${e.message}');
      throw Exception('Failed to fetch scenarios: ${e.message}');
    } catch (e) {
      safePrint('An unexpected error occurred: $e');
      rethrow;
    }
  }

  // nextTokenの計算（既存のロジックを維持）
  String _calculateNextToken(int offset) {
    return '{"offset":$offset}'; 
  }


  @override
  Future<List<String>> fetchAllAuthorNames() async {
     // ... (既存のロジックを維持) ...
     try {
       // Authorテーブルの全件を取得
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
         authorizationMode: APIAuthorizationType.apiKey,
      );

       final response = await Amplify.API.query(request: request).response;
       final data = response.data;

       if (data == null || response.hasErrors) {
         safePrint('GraphQL Errors fetching authors: ${response.errors}');
         throw Exception('Failed to fetch authors: ${response.errors}');
       }

       // AuthorNameのリストを抽出して返す
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

  // -----------------------------------------------------------
  // ▼▼▼ UserScenario関連のメソッド (DB連携に変更 - 修正版) ▼▼▼


  @override
  Future<List<UserScenario>> fetchMyList() async {
    // 自身の全 UserScenario データを取得（シナリオ情報もネストして取得）
    final userId = await _getCurrentUserId();

    // UserScenarioとScenarioをネストして取得するGraphQLクエリ
    final request = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
      document: '''
        query ListUserScenarios(\$filter: ModelUserScenarioFilterInput, \$limit: Int) {
          listUserScenarios(filter: \$filter, limit: \$limit) {
            items {
              id
              status
              scenario { # Scenarioオブジェクトをネストして取得
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
          'userId': {'eq': userId}, // フィルタのキー名はスキーマのフィールド名を使用
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

    // Amplifyモデルをドメインエンティティに変換
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

    // 1. レコードが未登録になる場合は削除を実行
    if (status.isUnregistered) {
      await removeUserScenarioStatus(scenarioId);
      return;
    }
    
    // 2. 既存のレコードを検索 (新しく作ったヘルパー関数を使用)
    final existing = await _findExistingUserScenario(userId, scenarioId);

    if (existing != null) {
      // 3. 既存レコードを更新
      final updatedModel = existing.copyWith(
        status: statusString,
      );
      // ★修正: ModelMutationsを使用し、Amplify.API.mutateにrequestのみを渡す
      await Amplify.API.mutate(
        request: ModelMutations.update(updatedModel),
      ).response;
      safePrint('Updated UserScenario for $scenarioId to $statusString');
    } else {
      // 4. 新規レコードを作成
      final newUserScenario = amplify_models.UserScenario(
        id: userId, // userIdをここで明示的に渡す
        // scenarioId: scenarioId, // scenarioIdをここで明示的に渡す
        status: statusString,
      );
      // ★修正: ModelMutationsを使用し、Amplify.API.mutateにrequestのみを渡す
      await Amplify.API.mutate(
        request: ModelMutations.create(newUserScenario),
      ).response;
      safePrint('Created new UserScenario for $scenarioId with status $statusString');
    }
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    final userId = await _getCurrentUserId();

    // 1. 既存のレコードを検索 (新しく作ったヘルパー関数を使用)
    final existing = await _findExistingUserScenario(userId, scenarioId);

    if (existing != null) {
      // 2. 既存レコードを削除
      // ★修正: ModelMutationsを使用し、Amplify.API.mutateにrequestのみを渡す
      await Amplify.API.mutate(
        request: ModelMutations.delete(existing),
      ).response;
      safePrint('Removed UserScenario for $scenarioId');
    } else {
      safePrint('UserScenario for $scenarioId not found, nothing to remove.');
    }
  }
}
// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart'; // RangeValuesのために必要
import 'dart:convert'; // ★ jsonDecode のために追加
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  // ★ キャッシュ用の変数を追加
  List<Scenario>? _cachedScenarios;
  Map<String, String>? _cachedAuthorMap;
  List<String>? _cachedAuthorNames;

  ScenarioRepositoryImpl() {
    // コンストラクタ内のダミーデータ生成ロジックは削除済み
  }

  // --- 共通ヘルパー関数: 現在認証済みのユーザーIDを取得 (変更なし) ---
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

  // ヘルパー関数: UserScenarioをFilterで検索し、既存レコードのIDを取得 (変更なし)
  Future<amplify_models.UserScenario?> _findExistingUserScenario(String userId, String scenarioId) async {
      // Raw GraphQL Queryを使用し、userIdとscenarioIdでレコードを検索
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

  // --- ★★★ ここから S3対応で修正 ★★★ ---

  // S3からAuthor Mapを取得する共通関数
  Future<Map<String, String>> _fetchAndCacheAuthorMap() async {
    if (_cachedAuthorMap != null) {
      return _cachedAuthorMap!;
    }
    
    try {
      // 1. S3から `Authors.json` をダウンロード
      // (S3の権限設定 'authAccess: ["READ"]' に合わせ、.protected を使用)
      final authorDownload = await Amplify.Storage.downloadData(
        key: 'Authors.json', // S3ルートに配置
        options: const StorageDownloadDataOptions(
          accessLevel: StorageAccessLevel.protected, 
        ),
      ).result;
      
      // ★ 修正: .data.bytes -> .bytes
      final authorList = jsonDecode(utf8.decode(authorDownload.bytes)) as List;
      
      // 2. 高速アクセスのため Author Map を作成 (authorId -> authorName)
      final authorMap = <String, String>{};
      for (var author in authorList) {
        // ★ isVisible: true の作者のみをマップに追加
        if (author['isVisible'] == true) {
          authorMap[author['authorId']] = author['authorName'];
        }
      }
      _cachedAuthorMap = authorMap;
      return _cachedAuthorMap!;

    } on StorageException catch (e) {
      safePrint('S3からのAuthorデータ取得に失敗しました: ${e.message}');
      throw Exception('作者データの取得に失敗しました: ${e.message}');
    } catch (e) {
      safePrint('Authorデータのパースに失敗しました: $e');
      throw Exception('作者データの処理に失敗しました: $e');
    }
  }

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page, // (S3化により page, limit, searchTerm 等はリポジトリ層では無視されます)
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    // 既にキャッシュがあればS3から再取得しない
    if (_cachedScenarios != null) {
      return _cachedScenarios!;
    }

    try {
      // 1. S3から `Authors.json` を取得 (キャッシュ利用)
      final authorMap = await _fetchAndCacheAuthorMap();

      // 2. S3から `Scenarios.json` をダウンロード
      final scenarioDownload = await Amplify.Storage.downloadData(
        key: 'Scenarios.json', // S3ルートに配置
        options: const StorageDownloadDataOptions(
          accessLevel: StorageAccessLevel.protected, 
        ),
      ).result;
      
      // ★ 修正: .data.bytes -> .bytes
      final scenarioList = jsonDecode(utf8.decode(scenarioDownload.bytes)) as List;

      // 3. JSONデータを Scenario エンティティに変換
      final List<Scenario> allScenarios = [];
      for (var scenarioJson in scenarioList) {
        // ★ フィルタリング:
        // 1. シナリオ自体が 'isVisible: true'
        // 2. AND シナリオの作者が (isVisible: true の) authorMap に存在する
        if (scenarioJson['isVisible'] == true && authorMap.containsKey(scenarioJson['authorId'])) {
          final authorName = authorMap[scenarioJson['authorId']]!;
          allScenarios.add(Scenario.fromJson(scenarioJson, authorName));
        }
      }
      
      _cachedScenarios = allScenarios;
      return _cachedScenarios!;

    } on StorageException catch (e) {
      safePrint('S3からのScenarioデータ取得に失敗しました: ${e.message}');
      throw Exception('シナリオデータの取得に失敗しました: ${e.message}');
    } catch (e) {
      safePrint('Scenarioデータのパースに失敗しました: $e');
      throw Exception('シナリオデータの処理に失敗しました: $e');
    }
  }

  @override
  Future<List<String>> fetchAllAuthorNames() async {
    if (_cachedAuthorNames != null) {
      return _cachedAuthorNames!;
    }
    
    try {
      // 1. S3から `Authors.json` を取得 (キャッシュ利用)
      final authorMap = await _fetchAndCacheAuthorMap();

      // 2. authorMap の値 (isVisible: true の authorName) からリストを作成
      _cachedAuthorNames = authorMap.values
          .toSet() // 重複除去
          .toList()
          ..sort(); // ソート
          
      return _cachedAuthorNames!;

    } catch (e) {
      safePrint('作者名の取得または処理に失敗しました: $e');
      rethrow;
    }
  }
  
  // --- ★★★ S3対応の修正ここまで ★★★ ---


  // --- fetchMyList (変更なし。Scenario.fromModel を使う) ---
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
                  id 
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
        // ★ 修正: Scenario.fromModel を正しく呼び出す
        final scenarioEntity = Scenario.fromModel(
          scenarioModel, 
          scenarioModel.author?.authorName ?? '不明な作者',
        );
        return UserScenario(
          scenario: scenarioEntity,
          status: UserScenarioStatus.fromString(us.status),
        );
      }).toList();
  }

  // --- updateUserScenarioStatus (変更なし) ---
  @override
  Future<void> updateUserScenarioStatus(
      String scenarioId, UserScenarioStatus status) async {
    final userId = await _getCurrentUserId();
    final statusString = status.toStringValue();

    if (status.isUnregistered) {
      // 未登録状態に戻す場合はレコードを削除
      await removeUserScenarioStatus(scenarioId);
      return;
    }
    
    // 1. 既存レコードを検索してIDを取得
    final existing = await _findExistingUserScenario(userId, scenarioId);

    if (existing != null) {
      // 2. 既存レコードを更新
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
            'id': existing.id, // 既存レコードのIDは必須
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
      // 3. 新規レコードを作成
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
            'userId': userId, // ★重要: userIdを直接渡す
            'scenarioId': scenarioId, // ★重要: scenarioIdを直接渡す
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
  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    final userId = await _getCurrentUserId();

    final existing = await _findExistingUserScenario(userId, scenarioId);

    if (existing != null) {
      // 2. 既存レコードを削除
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
            'id': existing.id, // 削除にはIDが必須
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
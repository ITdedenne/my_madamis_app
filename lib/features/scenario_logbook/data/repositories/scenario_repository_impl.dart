// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  List<Scenario>? _cachedScenarios;
  Map<String, String>? _cachedAuthorMap;
  List<String>? _cachedAuthorNames;

  ScenarioRepositoryImpl();

  Future<String> _getCurrentUserId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return attributes
          .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.sub) 
          .value;
    } on Exception catch (e) {
       safePrint('Failed to get current userId: $e');
       throw Exception('Authentication required to access user data.');
    }
  }

  // 複合キーを使って既存レコードを取得する
  Future<amplify_models.UserScenario?> _findExistingUserScenario(String userId, String scenarioId) async {
      try {
        final request = ModelQueries.get(
          amplify_models.UserScenario.classType,
          amplify_models.UserScenarioModelIdentifier(
            userId: userId,
            scenarioId: scenarioId,
          ),
        );
        final response = await Amplify.API.query(request: request).response;
        return response.data;
      } catch (e) {
        safePrint('Error finding existing user scenario: $e');
        return null;
      }
  }

  // --- S3関連処理 (変更なし) ---
  Future<Map<String, String>> _fetchAndCacheAuthorMap() async {
    if (_cachedAuthorMap != null) return _cachedAuthorMap!;
    
    try {
      final authorDownload = await Amplify.Storage.downloadData(
        key: 'Authors.json',
        options: const StorageDownloadDataOptions(accessLevel: StorageAccessLevel.guest),
      ).result;
      final authorList = jsonDecode(utf8.decode(authorDownload.bytes)) as List;
      final authorMap = <String, String>{};
      for (var author in authorList) {
        if (author['isVisible'] == true) {
          authorMap[author['authorId']] = author['authorName'];
        }
      }
      _cachedAuthorMap = authorMap;
      return _cachedAuthorMap!;
    } catch (e) {
      throw Exception('Failed to fetch authors: $e');
    }
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
    if (_cachedScenarios != null) return _cachedScenarios!;

    try {
      final authorMap = await _fetchAndCacheAuthorMap();
      final scenarioDownload = await Amplify.Storage.downloadData(
        key: 'Scenarios.json',
        options: const StorageDownloadDataOptions(accessLevel: StorageAccessLevel.guest),
      ).result;
      
      final scenarioList = jsonDecode(utf8.decode(scenarioDownload.bytes)) as List;
      final List<Scenario> allScenarios = [];
      for (var scenarioJson in scenarioList) {
        if (scenarioJson['isVisible'] == true && authorMap.containsKey(scenarioJson['authorId'])) {
          final authorName = authorMap[scenarioJson['authorId']]!;
          allScenarios.add(Scenario.fromJson(scenarioJson, authorName));
        }
      }
      _cachedScenarios = allScenarios;
      return _cachedScenarios!;
    } catch (e) {
      throw Exception('Failed to fetch scenarios: $e');
    }
  }

  @override
  Future<List<String>> fetchAllAuthorNames() async {
    if (_cachedAuthorNames != null) return _cachedAuthorNames!;
    final authorMap = await _fetchAndCacheAuthorMap();
    _cachedAuthorNames = authorMap.values.toSet().toList()..sort();
    return _cachedAuthorNames!;
  }
  
  // --- fetchMyList (変更なし) ---
  @override
  Future<List<UserScenario>> fetchMyList() async {
    final userId = await _getCurrentUserId();

    const queryDoc = r'''
      query ListUserScenarios($userId: ID!) {
        listUserScenarios(filter: { userId: { eq: $userId } }, limit: 2000) {
          items {
            userId
            scenarioId
            isPlayed
            isPossessed
            wantsToGm
          }
        }
      }
    ''';

    final request = GraphQLRequest<PaginatedResult<amplify_models.UserScenario>>(
      document: queryDoc,
      modelType: const PaginatedModelType(amplify_models.UserScenario.classType),
      variables: {'userId': userId},
      decodePath: 'listUserScenarios',
      authorizationMode: APIAuthorizationType.userPools, 
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.data == null || response.hasErrors) {
      throw Exception('Failed to fetch my list: ${response.errors}');
    }

    final userScenarioModels = response.data!.items.whereType<amplify_models.UserScenario>().toList();

    final allScenarios = await fetchScenarios(page: 1);

    final List<UserScenario> result = [];
    for (var usModel in userScenarioModels) {
      final scenario = allScenarios.firstWhereOrNull((s) => s.id == usModel.scenarioId);
      
      if (scenario != null) {
        result.add(UserScenario(
          scenario: scenario,
          status: UserScenarioStatus(
            isPlayed: usModel.isPlayed,
            isPossessed: usModel.isPossessed,
            wantsToGm: usModel.wantsToGm,
          ),
        ));
      }
    }
    return result;
  }

  // --- updateUserScenarioStatus ---
  @override
  Future<void> updateUserScenarioStatus(
      String scenarioId, UserScenarioStatus status) async {
    final userId = await _getCurrentUserId();

    // 【ここが重要】全てfalse (isUnregistered) なら削除処理へ分岐
    if (status.isUnregistered) {
      safePrint('Status is all false. Removing UserScenario: $scenarioId');
      await removeUserScenarioStatus(scenarioId);
      return;
    }
    
    // 登録・更新用のモデルを作成
    final userScenario = amplify_models.UserScenario(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: status.isPlayed,
      isPossessed: status.isPossessed,
      wantsToGm: status.wantsToGm,
    );

    try {
      final existing = await _findExistingUserScenario(userId, scenarioId);
      
      if (existing != null) {
         // 更新
         final updatedItem = existing.copyWith(
            isPlayed: status.isPlayed,
            isPossessed: status.isPossessed,
            wantsToGm: status.wantsToGm,
         );
         await Amplify.API.mutate(request: ModelMutations.update(updatedItem)).response;
         safePrint('Updated UserScenario: $scenarioId');
      } else {
         // 新規作成
         await Amplify.API.mutate(request: ModelMutations.create(userScenario)).response;
         safePrint('Created UserScenario: $scenarioId');
      }
    } catch (e) {
      safePrint('Error updating scenario status: $e');
      throw Exception('ステータスの更新に失敗しました');
    }
  }

  // --- removeUserScenarioStatus (修正版) ---
  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    final userId = await _getCurrentUserId();

    try {
      // 1. まず確実に既存データを取得する
      final existing = await _findExistingUserScenario(userId, scenarioId);

      if (existing != null) {
        // 2. 取得したモデルインスタンスそのものを渡して削除する（最も確実な方法）
        final request = ModelMutations.delete(existing);
        final response = await Amplify.API.mutate(request: request).response;
        
        if (response.hasErrors) {
           safePrint('削除中にGraphQLエラーが発生しました: ${response.errors}');
        } else {
           safePrint('Removed UserScenario successfully: $scenarioId');
        }
      } else {
        safePrint('削除対象のUserScenarioが見つかりませんでした (すでに削除済みの可能性があります): $scenarioId');
      }
    } catch (e) {
      safePrint('Error deleting scenario: $e');
      // 削除に関しては、すでに無い場合のエラーは無視してもUX上問題ない場合が多いですが、
      // ログには残しておきます。
    }
  }
}
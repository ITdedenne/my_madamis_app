// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

// 1. ドメイン層のエンティティをインポート
import '../../domain/entities/scenario.dart';
import '../../domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

// 2. Amplify生成モデルを「models」としてインポート（名前の衝突を避ける）
import '../../../../models/ModelProvider.dart' as models;

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  // ---------------------------------------------------------------------------
  // 内部ユーティリティ: S3から全シナリオをフェッチする
  // ---------------------------------------------------------------------------
  Future<List<Scenario>> _fetchAllScenariosFromS3() async {
    // S3はv1でも .result で取得します
    final scenariosResult = await Amplify.Storage.downloadData(key: 'Scenarios.json').result;
    final authorsResult = await Amplify.Storage.downloadData(key: 'Authors.json').result;

    final List<dynamic> rawScenarios = jsonDecode(utf8.decode(scenariosResult.bytes));
    final List<dynamic> rawAuthors = jsonDecode(utf8.decode(authorsResult.bytes));

    final Map<String, String> authorMap = {
      for (var a in rawAuthors) a['authorId'] as String: a['name'] as String
    };

    return rawScenarios.map((json) {
      final aId = json['authorId'] as String;
      final aName = authorMap[aId] ?? 'Unknown';
      return Scenario.fromJson(json, aName);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 1. シナリオマスターデータ (S3 / JSON)
  // ---------------------------------------------------------------------------

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 48, // 要件定義 9.2 準拠
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    try {
      List<Scenario> allScenarios = await _fetchAllScenariosFromS3();

      // フィルタリング
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final query = searchTerm.toLowerCase();
        allScenarios = allScenarios.where((s) => s.titleLower.contains(query)).toList();
      }
      if (playerCountRange != null) {
        allScenarios = allScenarios.where((s) =>
            s.minPlayerCount >= playerCountRange.start &&
            s.maxPlayerCount <= playerCountRange.end).toList();
      }
      if (gmRequirement != null) {
        allScenarios = allScenarios.where((s) => s.gmRequirement == gmRequirement).toList();
      }
      if (authorName != null && authorName.isNotEmpty) {
        allScenarios = allScenarios.where((s) => s.authorName == authorName).toList();
      }

      final startIndex = (page - 1) * limit;
      if (startIndex >= allScenarios.length) return [];
      final endIndex = (startIndex + limit) > allScenarios.length ? allScenarios.length : startIndex + limit;
      return allScenarios.sublist(startIndex, endIndex);
    } catch (e) {
      safePrint('fetchScenariosエラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchAllAuthorNames() async {
    try {
      final result = await Amplify.Storage.downloadData(key: 'Authors.json').result;
      final List<dynamic> rawAuthors = jsonDecode(utf8.decode(result.bytes));
      return rawAuthors.map((a) => a['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 2. ユーザー個別データ (AppSync / DynamoDB)
  // ---------------------------------------------------------------------------

  @override
  Future<List<UserScenario>> fetchMyList() async {
    final authUser = await Amplify.Auth.getCurrentUser();
    return fetchUserScenarios(authUser.userId);
  }

  @override
  Future<List<UserScenario>> fetchUserScenarios(String userId) async {
    try {
      final request = ModelQueries.list(
        models.UserScenario.classType,
        where: models.UserScenario.USERID.eq(userId),
      );
      
      // 【修正】 Amplify API v1 は .response で取得する
      final operation = Amplify.API.query(request: request);
      final response = await operation.response;
      final items = response.data?.items ?? [];

      // S3からマスターデータを取得してマップ化（シナリオの結合用）
      final allScenarios = await _fetchAllScenariosFromS3();
      final scenarioMap = { for (var s in allScenarios) s.id: s };

      final List<UserScenario> userScenarios = [];

// fetchUserScenarios メソッド内の userScenarios.add の直前
      for (final m in items.whereType<models.UserScenario>()) {
        // ★ m.scenarioId が null の場合はスキップする防御策を追加
        if (m.scenarioId == null) continue; 
        
        final scenario = scenarioMap[m.scenarioId];
        if (scenario != null) {
          final status = UserScenarioStatus(
            isPlayed: m.isPlayed,
            isPossessed: m.isPossessed,
            wantsToGm: m.wantsToGm,
            wantsToPlay: m.wantsToPlay ?? false,
          );
          // 【修正】 ドメインモデルのコンストラクタ（scenario, status）に適合させる
          userScenarios.add(UserScenario(scenario: scenario, status: status));
        }
      }

      return userScenarios;
    } catch (e) {
      safePrint('fetchUserScenariosエラー: $e');
      return [];
    }
  }

  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      
      final newModel = models.UserScenario(
        userId: authUser.userId,
        scenarioId: scenarioId,
        isPlayed: status.isPlayed,
        isPossessed: status.isPossessed,
        wantsToGm: status.wantsToGm,
        wantsToPlay: status.wantsToPlay,
      );

      final request = ModelMutations.create(newModel);
      // 【修正】 .result ではなく .response
      await Amplify.API.mutate(request: request).response;
    } catch (e) {
      safePrint('updateUserScenarioStatusエラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      
      // 【修正】 識別子クラス名が UserScenarioModelIdentifier になっている
      final request = ModelQueries.get(
        models.UserScenario.classType,
        models.UserScenarioModelIdentifier(userId: authUser.userId, scenarioId: scenarioId),
      );
      // 【修正】 .result ではなく .response
      final response = await Amplify.API.query(request: request).response;
      final target = response.data;

      if (target != null) {
        final deleteRequest = ModelMutations.delete(target);
        await Amplify.API.mutate(request: deleteRequest).response; // 【修正】 .response
      }
    } catch (e) {
      safePrint('removeUserScenarioStatusエラー: $e');
    }
  }
}
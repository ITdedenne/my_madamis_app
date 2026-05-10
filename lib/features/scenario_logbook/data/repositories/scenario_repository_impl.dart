// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

// 1. ドメイン層のエンティティをインポート
import '../../domain/entities/scenario.dart';
import '../../domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

// 2. Amplify生成モデルを「models」としてインポート
import '../../../../models/ModelProvider.dart' as models;

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  // ---------------------------------------------------------------------------
  // 内部ユーティリティ: S3から全シナリオをフェッチする
  // ---------------------------------------------------------------------------
  Future<List<Scenario>> _fetchAllScenariosFromS3() async {
    try {
      final scenariosResult = await Amplify.Storage.downloadData(key: 'Scenarios.json').result;
      final authorsResult = await Amplify.Storage.downloadData(key: 'Authors.json').result;

      final List<dynamic> rawScenarios = jsonDecode(utf8.decode(scenariosResult.bytes));
      final List<dynamic> rawAuthors = jsonDecode(utf8.decode(authorsResult.bytes));

      // 【修正ポイント】 Authors.json のキーは 'authorName' です
      final Map<String, String> authorMap = {
        for (var a in rawAuthors) 
          (a['authorId']?.toString() ?? ''): (a['authorName']?.toString() ?? '不明')
      };

      return rawScenarios.map((json) {
        final aId = json['authorId']?.toString() ?? '';
        final aName = authorMap[aId] ?? '不明';
        return Scenario.fromJson(json, aName);
      }).toList();
    } catch (e) {
      safePrint('S3フェッチエラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 48,
    String? searchTerm,
    RangeValues? playerCountRange,
    GmRequirement? gmRequirement,
    String? authorName,
  }) async {
    try {
      List<Scenario> allScenarios = await _fetchAllScenariosFromS3();

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
      return [];
    }
  }

  @override
  Future<List<String>> fetchAllAuthorNames() async {
    try {
      final result = await Amplify.Storage.downloadData(key: 'Authors.json').result;
      final List<dynamic> rawAuthors = jsonDecode(utf8.decode(result.bytes));
      // 【修正ポイント】 キー名を 'authorName' に修正
      return rawAuthors.map((a) => (a['authorName']?.toString() ?? '不明')).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UserScenario>> fetchMyList() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      return fetchUserScenarios(authUser.userId);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UserScenario>> fetchUserScenarios(String userId) async {
    try {
      final request = ModelQueries.list(
        models.UserScenario.classType,
        where: models.UserScenario.USERID.eq(userId),
      );
      
      final operation = Amplify.API.query(request: request);
      final response = await operation.response;
      final items = response.data?.items ?? [];

      final allScenarios = await _fetchAllScenariosFromS3();
      final scenarioMap = { for (var s in allScenarios) s.id: s };

      final List<UserScenario> userScenarios = [];

      for (final m in items.whereType<models.UserScenario>()) {
        if (m.scenarioId == null) continue;
        final scenario = scenarioMap[m.scenarioId];
        if (scenario != null) {
          final status = UserScenarioStatus(
            isPlayed: m.isPlayed,
            isPossessed: m.isPossessed,
            wantsToGm: m.wantsToGm,
            wantsToPlay: m.wantsToPlay ?? false,
          );
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
      
      var newModel = models.UserScenario(
        userId: authUser.userId,
        scenarioId: scenarioId,
        isPlayed: status.isPlayed,
        isPossessed: status.isPossessed,
        wantsToGm: status.wantsToGm,
      );

      // copyWith を使用して Nullable フィールドをセット
      newModel = newModel.copyWith(wantsToPlay: status.wantsToPlay);

      final request = ModelMutations.create(newModel);
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
      final request = ModelQueries.get(
        models.UserScenario.classType,
        models.UserScenarioModelIdentifier(userId: authUser.userId, scenarioId: scenarioId),
      );
      final response = await Amplify.API.query(request: request).response;
      final target = response.data;

      if (target != null) {
        final deleteRequest = ModelMutations.delete(target);
        await Amplify.API.mutate(request: deleteRequest).response;
      }
    } catch (e) {
      safePrint('removeUserScenarioStatusエラー: $e');
    }
  }
}
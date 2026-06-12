// lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/scenario.dart';
import '../../domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../../../../models/ModelProvider.dart' as models;

class ScenarioRepositoryImpl implements ScenarioRepository {
  
  // ---------------------------------------------------------------------------
  // 内部ユーティリティ: S3からJSONをフェッチする（ローカルキャッシュ付き）
  // ---------------------------------------------------------------------------
  Future<String> _getS3DataWithCache(String fileKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cache_$fileKey';
      final timeKey = 'time_$fileKey';

      final cachedData = prefs.getString(cacheKey);
      final cachedTimeStr = prefs.getString(timeKey);

      // 1. キャッシュが存在し、かつ保存から24時間以内かチェックする
      if (cachedData != null && cachedTimeStr != null) {
        final cachedTime = DateTime.tryParse(cachedTimeStr);
        if (cachedTime != null && DateTime.now().difference(cachedTime).inHours < 24) {
          return cachedData; // 24時間以内ならローカル保存データを即座に返す（S3通信なし）
        }
      }

      // 2. キャッシュがない、または24時間以上経過している場合はS3から取得
      final result = await Amplify.Storage.downloadData(key: fileKey).result;
      final jsonString = utf8.decode(result.bytes);

      // 3. 取得したデータをブラウザのローカルストレージに保存（次回以降のため）
      await prefs.setString(cacheKey, jsonString);
      await prefs.setString(timeKey, DateTime.now().toIso8601String());

      return jsonString;
    } catch (e) {
      safePrint('キャッシュ/S3フェッチエラー ($fileKey): $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 内部ユーティリティ: キャッシュを利用して全シナリオを組み立てる
  // ---------------------------------------------------------------------------
  Future<List<Scenario>> _fetchAllScenariosFromS3() async {
    try {
      // キャッシュ付きのメソッド経由でJSON文字列を取得する
      final scenariosJsonStr = await _getS3DataWithCache('Scenarios.json');
      final authorsJsonStr = await _getS3DataWithCache('Authors.json');

      final List<dynamic> rawScenarios = jsonDecode(scenariosJsonStr);
      final List<dynamic> rawAuthors = jsonDecode(authorsJsonStr);

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
      safePrint('_fetchAllScenariosFromS3エラー: $e');
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
      // キャッシュ付きメソッド経由でJSON文字列を取得する
      final authorsJsonStr = await _getS3DataWithCache('Authors.json');
      final List<dynamic> rawAuthors = jsonDecode(authorsJsonStr);
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
      
      // 1. まず既存のデータが存在するか確認する
      final getRequest = ModelQueries.get(
        models.UserScenario.classType,
        models.UserScenarioModelIdentifier(userId: authUser.userId, scenarioId: scenarioId),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;
      final existingRecord = getResponse.data;

      if (existingRecord != null) {
        // 2. 既存データがある場合は「更新 (Update)」する
        final updatedModel = existingRecord.copyWith(
          isPlayed: status.isPlayed,
          isPossessed: status.isPossessed,
          wantsToGm: status.wantsToGm,
          wantsToPlay: status.wantsToPlay,
        );

        final updateRequest = ModelMutations.update(updatedModel);
        final response = await Amplify.API.mutate(request: updateRequest).response;
        
        // サーバー側でエラーが返ってきた場合は例外を投げる
        if (response.hasErrors) {
          throw Exception('更新中にエラーが発生しました: ${response.errors}');
        }
      } else {
        // 3. 既存データがない場合は「新規作成 (Create)」する
        var newModel = models.UserScenario(
          userId: authUser.userId,
          scenarioId: scenarioId,
          isPlayed: status.isPlayed,
          isPossessed: status.isPossessed,
          wantsToGm: status.wantsToGm,
          wantsToPlay: status.wantsToPlay ?? false,
        );

        final createRequest = ModelMutations.create(newModel);
        final response = await Amplify.API.mutate(request: createRequest).response;
        
        // サーバー側でエラーが返ってきた場合は例外を投げる
        if (response.hasErrors) {
          throw Exception('作成中にエラーが発生しました: ${response.errors}');
        }
      }
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
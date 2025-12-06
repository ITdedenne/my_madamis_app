// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

// --- 定数定義 ---
const String _kScenariosFileName = 'Scenarios.json';
const String _kAuthorsFileName = 'Authors.json';
const String _kVersionFileName = 'version.json';
const String _kLocalVersionFileName = 'local_version.json';

// --- トップレベル関数 (変更なし) ---
List<Scenario> _parseScenarios(Map<String, dynamic> data) {
  final jsonString = data['jsonString'] as String;
  final authorMap = data['authorMap'] as Map<String, String>;

  final scenarioList = jsonDecode(jsonString) as List;
  final List<Scenario> allScenarios = [];
  for (var scenarioJson in scenarioList) {
    if (scenarioJson['isVisible'] == true && authorMap.containsKey(scenarioJson['authorId'])) {
      final authorName = authorMap[scenarioJson['authorId']]!;
      allScenarios.add(Scenario.fromJson(scenarioJson, authorName));
    }
  }
  return allScenarios;
}

Map<String, String> _parseAuthors(String jsonString) {
  final authorList = jsonDecode(jsonString) as List;
  final authorMap = <String, String>{};
  for (var author in authorList) {
    if (author['isVisible'] == true) {
      authorMap[author['authorId']] = author['authorName'];
    }
  }
  return authorMap;
}

class ScenarioRepositoryImpl implements ScenarioRepository {
  List<Scenario>? _cachedScenarios;
  Map<String, String>? _cachedAuthorMap;
  List<String>? _cachedAuthorNames;

  ScenarioRepositoryImpl();

  Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  // ★ 修正: ファイルごとにバージョンを比較・更新するロジックに変更
  Future<void> _checkVersionAndSync() async {
    try {
      // 1. S3から最新のバージョン情報を取得
      final s3Download = await Amplify.Storage.downloadData(
        key: _kVersionFileName,
        options: const StorageDownloadDataOptions(
            accessLevel: StorageAccessLevel.guest),
      ).result;
      
      final s3VersionJson = utf8.decode(s3Download.bytes);
      final Map<String, dynamic> s3Versions = jsonDecode(s3VersionJson);

      // 2. ローカルのバージョン情報を確認
      final localVersionFile = await _getLocalFile(_kLocalVersionFileName);
      Map<String, dynamic> localVersions = {};
      if (await localVersionFile.exists()) {
        try {
          localVersions = jsonDecode(await localVersionFile.readAsString());
        } catch (_) {
          // 読み込みエラー時は空にして全更新を促す
          localVersions = {};
        }
      }

      bool hasUpdates = false;

      // 3. Authors.json のチェック
      final s3AuthorsVer = s3Versions['authors']?.toString() ?? '0';
      final localAuthorsVer = localVersions['authors']?.toString() ?? '';
      
      if (s3AuthorsVer != localAuthorsVer) {
        safePrint('Authors update detected ($localAuthorsVer -> $s3AuthorsVer). Downloading...');
        await _fetchDataWithCache(_kAuthorsFileName, forceRefresh: true);
        hasUpdates = true;
        // メモリキャッシュもクリア
        _cachedAuthorMap = null;
        _cachedAuthorNames = null;
      }

      // 4. Scenarios.json のチェック
      final s3ScenariosVer = s3Versions['scenarios']?.toString() ?? '0';
      final localScenariosVer = localVersions['scenarios']?.toString() ?? '';

      if (s3ScenariosVer != localScenariosVer) {
        safePrint('Scenarios update detected ($localScenariosVer -> $s3ScenariosVer). Downloading...');
        await _fetchDataWithCache(_kScenariosFileName, forceRefresh: true);
        hasUpdates = true;
        // メモリキャッシュもクリア
        _cachedScenarios = null;
      }

      // 5. 更新があった場合のみ、ローカルのバージョンファイルを書き換える
      if (hasUpdates || !await localVersionFile.exists()) {
        await localVersionFile.writeAsString(s3VersionJson);
        safePrint('Local version file updated.');
      } else {
        safePrint('Cache is up to date.');
      }

    } catch (e) {
      safePrint('Version check failed: $e. Using existing cache if available.');
    }
  }

  Future<String> _fetchDataWithCache(String filename, {bool forceRefresh = false}) async {
    final file = await _getLocalFile(filename);

    if (!forceRefresh && await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          // safePrint('Loaded $filename from local cache.'); // ログ過多を防ぐためコメントアウト可
          return content;
        }
      } catch (e) {
        safePrint('Error reading local cache for $filename: $e');
      }
    }

    try {
      safePrint('Downloading $filename from S3...');
      final downloadResult = await Amplify.Storage.downloadData(
        key: filename,
        options: const StorageDownloadDataOptions(
            accessLevel: StorageAccessLevel.guest),
      ).result;

      final jsonString = utf8.decode(downloadResult.bytes);
      await file.writeAsString(jsonString);
      return jsonString;
    } catch (e) {
      if (await file.exists()) {
        safePrint('Fallback to local cache for $filename due to error: $e');
        return await file.readAsString();
      }
      rethrow;
    }
  }

  // ... (以下、前回と同じメソッド群)
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

  Future<amplify_models.UserScenario?> _findExistingUserScenario(
      String userId, String scenarioId) async {
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

  Future<Map<String, String>> _fetchAndCacheAuthorMap() async {
    if (_cachedAuthorMap != null) return _cachedAuthorMap!;

    try {
      final jsonString = await _fetchDataWithCache(_kAuthorsFileName);
      _cachedAuthorMap = await compute(_parseAuthors, jsonString);
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
      // 1. バージョンチェックと同期 (差分のみ更新)
      await _checkVersionAndSync();

      // 2. データをロード (更新があれば新しいものが読まれる)
      final authorMap = await _fetchAndCacheAuthorMap();
      final jsonString = await _fetchDataWithCache(_kScenariosFileName);
      
      _cachedScenarios = await compute(_parseScenarios, {
        'jsonString': jsonString,
        'authorMap': authorMap,
      });
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

  @override
  Future<List<UserScenario>> fetchMyList() async {
    final userId = await _getCurrentUserId();
    return fetchUserScenarios(userId);
  }

  @override
  Future<List<UserScenario>> fetchUserScenarios(String userId) async {
    const queryDoc = r'''
      query ListUserScenarios($userId: ID!) {
        listUserScenarios(filter: { userId: { eq: $userId } }, limit: 2000) {
          items {
            userId
            scenarioId
            isPlayed
            isPossessed
            wantsToGm
            wantsToPlay
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
      throw Exception('Failed to fetch user scenarios: ${response.errors}');
    }

    final userScenarioModels = response.data!.items
        .whereType<amplify_models.UserScenario>()
        .toList();

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
            wantsToPlay: usModel.wantsToPlay ?? false,
          ),
        ));
      }
    }
    return result;
  }

  @override
  Future<void> updateUserScenarioStatus(
      String scenarioId, UserScenarioStatus status) async {
    final userId = await _getCurrentUserId();

    if (status.isUnregistered) {
      await removeUserScenarioStatus(scenarioId);
      return;
    }

    final userScenario = amplify_models.UserScenario(
      userId: userId,
      scenarioId: scenarioId,
      isPlayed: status.isPlayed,
      isPossessed: status.isPossessed,
      wantsToGm: status.wantsToGm,
      wantsToPlay: status.wantsToPlay,
    );

    try {
      final existing = await _findExistingUserScenario(userId, scenarioId);

      if (existing != null) {
        final updatedItem = existing.copyWith(
          isPlayed: status.isPlayed,
          isPossessed: status.isPossessed,
          wantsToGm: status.wantsToGm,
          wantsToPlay: status.wantsToPlay,
        );
        await Amplify.API.mutate(request: ModelMutations.update(updatedItem)).response;
      } else {
        await Amplify.API.mutate(request: ModelMutations.create(userScenario)).response;
      }
    } catch (e) {
      safePrint('Error updating scenario status: $e');
      throw Exception('ステータスの更新に失敗しました');
    }
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
    final userId = await _getCurrentUserId();

    try {
      final existing = await _findExistingUserScenario(userId, scenarioId);

      if (existing != null) {
        final request = ModelMutations.delete(existing);
        await Amplify.API.mutate(request: request).response;
      }
    } catch (e) {
      safePrint('Error deleting scenario: $e');
    }
  }
}
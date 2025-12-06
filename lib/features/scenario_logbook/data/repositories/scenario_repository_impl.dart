// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart'; // compute用
import 'dart:convert';
import 'dart:io'; // ★ 追加: File操作用
import 'package:path_provider/path_provider.dart'; // ★ 追加: パス取得用
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

// --- 定数定義 ---
const String _kScenariosFileName = 'Scenarios.json';
const String _kAuthorsFileName = 'Authors.json';
const String _kVersionFileName = 'version.json'; // ★ 追加: S3上のバージョンファイル名
const String _kLocalVersionFileName = 'local_version.json'; // ★ 追加: ローカル保存用バージョンファイル名

// --- トップレベル関数 (compute用: 変更なし) ---
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

  // ★ 追加: ローカルファイルのパスを取得するヘルパー関数
  Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  // ★ 追加: バージョンチェックを行い、必要ならデータを更新するメソッド
  Future<void> _checkVersionAndSync() async {
    try {
      // 1. S3から最新のバージョン情報を取得 (サイズが小さいので毎回取得してもOK)
      final s3Download = await Amplify.Storage.downloadData(
        key: _kVersionFileName,
        options: const StorageDownloadDataOptions(
            accessLevel: StorageAccessLevel.guest),
      ).result;
      
      final s3VersionJson = utf8.decode(s3Download.bytes);
      final s3VersionMap = jsonDecode(s3VersionJson);
      final String s3Version = s3VersionMap['version'] ?? '0.0.0';

      // 2. ローカルのバージョン情報を確認
      final localVersionFile = await _getLocalFile(_kLocalVersionFileName);
      String localVersion = '0.0.0';
      if (await localVersionFile.exists()) {
        final localVersionJson = await localVersionFile.readAsString();
        final localVersionMap = jsonDecode(localVersionJson);
        localVersion = localVersionMap['version'] ?? '0.0.0';
      }

      // 3. バージョン比較 (異なれば更新)
      if (s3Version != localVersion) {
        safePrint('New version detected (S3: $s3Version, Local: $localVersion). Updating cache...');
        
        // データを強制ダウンロードしてキャッシュを更新
        await _fetchDataWithCache(_kAuthorsFileName, forceRefresh: true);
        await _fetchDataWithCache(_kScenariosFileName, forceRefresh: true);

        // 新しいバージョンをローカルに保存
        await localVersionFile.writeAsString(s3VersionJson);
        
        // メモリキャッシュもクリアして再読み込みを促す
        _cachedScenarios = null;
        _cachedAuthorMap = null;
        _cachedAuthorNames = null;
        
        safePrint('Cache updated to version $s3Version');
      } else {
        safePrint('Local cache is up to date (Version: $localVersion).');
      }
    } catch (e) {
      // オフラインやS3エラー時はログを出してスルー (既存キャッシュを使うため)
      safePrint('Version check failed: $e. Using existing cache if available.');
    }
  }

  // ★ 追加: ローカルデータの読み込みと、なければS3から取得して保存する共通ロジック
  Future<String> _fetchDataWithCache(String filename, {bool forceRefresh = false}) async {
    final file = await _getLocalFile(filename);

    // 1. 強制更新でなく、かつファイルが存在する場合はローカルから読み込む
    if (!forceRefresh && await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          safePrint('Loaded $filename from local cache.');
          return content;
        }
      } catch (e) {
        safePrint('Error reading local cache for $filename: $e');
        // エラー時はS3からの取得へ進む
      }
    }

    // 2. S3からダウンロード
    try {
      safePrint('Downloading $filename from S3...');
      final downloadResult = await Amplify.Storage.downloadData(
        key: filename,
        options: const StorageDownloadDataOptions(
            accessLevel: StorageAccessLevel.guest),
      ).result;

      final jsonString = utf8.decode(downloadResult.bytes);

      // 3. ローカルに保存 (次回以降のため)
      await file.writeAsString(jsonString);
      safePrint('Saved $filename to local cache.');

      return jsonString;
    } catch (e) {
      safePrint('Failed to download $filename: $e');
      // ダウンロード失敗時、もし古いキャッシュがあればそれを使う（オフライン対応）
      if (await file.exists()) {
        safePrint('Fallback to local cache for $filename');
        return await file.readAsString();
      }
      rethrow;
    }
  }

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

  // ★ 修正: キャッシュロジックを使用
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
      // ★ 1. まずバージョンチェックと同期を実行 (ここで必要なら強制更新が走る)
      await _checkVersionAndSync();

      // ★ 2. 作者データを取得 (ローカルキャッシュ優先)
      final authorMap = await _fetchAndCacheAuthorMap();
      
      // ★ 3. シナリオデータを取得 (ローカルキャッシュ優先)
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
    // 内部でキャッシュロジックを利用する _fetchAndCacheAuthorMap を呼ぶ
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

    // ★ ここでもキャッシュが効くので高速
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
            wantsToPlay: usModel.wantsToPlay ?? false, // Nullable対応
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
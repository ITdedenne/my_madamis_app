// ファイルパス: lib/features/scenario_logbook/data/repositories/scenario_repository_impl.dart

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart'; // RangeValuesのために必要
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import '../../domain/repositories/scenario_repository.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  // --- Scenario/Author関連のダミーデータは削除 ---

  ScenarioRepositoryImpl() {
    // --- コンストラクタ内のダミーデータ生成ロジックを削除 ---
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
    try {
      // 1. GraphQLクエリの準備 (フィルター条件を含む)
      // Amplify GraphQL FilterInput 形式のマップを構築
      final Map<String, dynamic> filter = {};
      final List<Map<String, dynamic>> orConditions = [];

      // 検索語 (タイトル or 作者名)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        orConditions.add({
          'title': {'contains': searchTerm}
        });
        // author.authorName での直接の 'or' フィルターは Amplify V1 では複雑なため、
        // クライアントサイドでのフィルタリング、または
        // @searchable ディレクティブの使用を検討する必要があります。
        // ここではタイトル検索のみをフィルターに入れ、作者名検索はクライアントサイドで行います。
        // (もし @searchable を使っている場合はクエリを変更できます)
      }

      // GM要否
      if (gmRequirement != null) {
        filter['gmRequirement'] = {'eq': gmRequirement.toGraphQLString()};
      }

      // プレイ人数 (GraphQLでの単純な範囲絞り込み)
      // シナリオの範囲(min-max)が検索範囲(start-end)に一部でも重なるように
      // (min <= end AND max >= start)
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

      // GraphQLリクエストの作成
      // ▼▼▼ エラー修正 ▼▼▼
      // 'amplify_models.PaginatedResult' -> 'PaginatedResult'
      // 'amplify_models.PaginatedModelType' -> 'PaginatedModelType'
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
        // ▲▲▲ エラー修正 ▲▲▲
        variables: {
          'filter': filter.isNotEmpty ? filter : null,
          'limit': limit,
          'nextToken': page > 1 ? _calculateNextToken(offset) : null, // 仮のnextToken計算
        },
        // decodePathを指定
        decodePath: 'listScenarios', 
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
              // Author名がない場合は空文字にする
              final authorNameStr = scenarioModel!.author?.authorName ?? '';
              return Scenario.fromModel(scenarioModel, authorNameStr);
            })
          .toList();

      // クライアントサイドでのフィルタリング (GraphQLで対応しきれない分)
      
      // 作者名 (直接指定)
      if (authorName != null && authorName.isNotEmpty) {
        scenarios = scenarios.where((s) => s.authorName == authorName).toList();
      }

      // 検索語 (作者名での 'or' 検索)
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
      rethrow; // ViewModelでハンドリングできるよう再スロー
    }
  }

  // nextTokenの計算（これはAmplifyの具体的な実装に依存するため、あくまで仮の例）
  // 実際には、Amplifyが返すnextTokenを次のクエリに渡すのが一般的です。
  // int (page) から nextToken (String) への変換は通常行いません。
  // 本番実装では、ViewModelでnextTokenを状態として保持し、
  // このメソッドの引数で page ではなく nextToken を受け取るべきです。
  String _calculateNextToken(int offset) {
    // この仮実装は期待通り動作しない可能性が高いです。
    // AmplifyのページネーションはレスポンスのnextTokenを使う必要があります。
    // 簡易的なオフセットベースのページネーション（非推奨）
    return '{"offset":$offset}'; // 仮のトークン形式
  }


  @override
  Future<List<String>> fetchAllAuthorNames() async {
     try {
       // Authorテーブルの全件を取得 (limitを大きく設定)
       const graphQLDocument = '''
         query ListAuthors(\$limit: Int) {
           listAuthors(limit: \$limit) {
             items {
               authorName
             }
           }
         }
       ''';

      // ▼▼▼ エラー修正 ▼▼▼
      // 'amplify_models.PaginatedResult' -> 'PaginatedResult'
      // 'amplify_models.PaginatedModelType' -> 'PaginatedModelType'
      final request = GraphQLRequest<PaginatedResult<amplify_models.Author>>(
         document: graphQLDocument,
         modelType: const PaginatedModelType(amplify_models.Author.classType),
         // ▲▲▲ エラー修正 ▲▲▲
         variables: {'limit': 1000}, // 仮に1000件まで取得
         decodePath: 'listAuthors',
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
           .toSet() // 重複を除去
           .toList()
           ..sort(); // ソート

     } on ApiException catch (e) {
       safePrint('Failed to fetch author names: ${e.message}');
       throw Exception('Failed to fetch author names: ${e.message}');
     } catch (e) {
       safePrint('An unexpected error occurred fetching author names: $e');
       rethrow;
     }
  }

  // --- UserScenario関連のメソッド (ダミーデータのまま) ---

  // ユーザーのシナリオステータス（ダミーデータ）
  final Map<String, UserScenarioStatus> _userStatuses = {
    // ダミーデータをいくつか入れておく
     'scenario_abc': const UserScenarioStatus(isPlayed: true),
     'scenario_def': const UserScenarioStatus(isPossessed: true),
     'scenario_ghi': const UserScenarioStatus(isPlayed: true, isPossessed: true),
     'scenario_0': const UserScenarioStatus(isPlayed: true),
     'scenario_1': const UserScenarioStatus(isPossessed: true),
     'scenario_2': const UserScenarioStatus(isPlayed: true, isPossessed: true),
  };

  // 仮の全シナリオリスト（fetchMyListで参照するため）
  // 本来はfetchScenarios等で取得したデータを使うべきだが、
  // UserScenarioがダミーデータ運用中は整合性を取るのが難しいため、
  // ここでも仮のデータを使う。
   final List<Scenario> _dummyAllScenariosForMyList = List.generate(10, (index) => Scenario(
     id: 'scenario_$index', 
     title: '仮シナリオ $index',
     authorName: '仮作者 ${index % 3}',
     authorId: 'author_${index % 3}',
     minPlayerCount: 3 + index % 2,
     maxPlayerCount: 5 + index % 3,
     gmRequirement: GmRequirement.values[index % 3],
   ))
   ..addAll([
     const Scenario(
       id: 'scenario_abc', title: '仮シナリオ ABC', authorName: '仮作者 A', authorId: 'author_A',
       minPlayerCount: 4, maxPlayerCount: 5, gmRequirement: GmRequirement.required
     ),
     const Scenario(
       id: 'scenario_def', title: '仮シナリオ DEF', authorName: '仮作者 B', authorId: 'author_B',
       minPlayerCount: 5, maxPlayerCount: 5, gmRequirement: GmRequirement.optional
     ),
     const Scenario(
       id: 'scenario_ghi', title: '仮シナリオ GHI', authorName: '仮作者 A', authorId: 'author_A',
       minPlayerCount: 6, maxPlayerCount: 8, gmRequirement: GmRequirement.none
     ),
   ]);


  @override
  Future<List<UserScenario>> fetchMyList() async {
    await Future.delayed(const Duration(milliseconds: 100)); // ネットワーク遅延を模倣

    // _userStatusesにあるIDのシナリオ情報（ダミー）を取得して結合
    return _userStatuses.entries.map((entry) {
      final scenario = _dummyAllScenariosForMyList.firstWhere(
            (s) => s.id == entry.key,
            orElse: () => Scenario( // 見つからない場合は最低限のダミーを返す
                id: entry.key, title: '不明なシナリオ', authorName: '不明', authorId: '',
                minPlayerCount: 0, maxPlayerCount: 0, gmRequirement: GmRequirement.none)
      );
      return UserScenario(scenario: scenario, status: entry.value);
    }).toList();
  }

  @override
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200)); // DB更新を模倣
    if (status.isUnregistered) {
      _userStatuses.remove(scenarioId);
      safePrint('Removed status for $scenarioId. Current statuses: $_userStatuses');
    } else {
      _userStatuses[scenarioId] = status;
      safePrint('Updated status for $scenarioId to $status. Current statuses: $_userStatuses');
    }
  }

  @override
  Future<void> removeUserScenarioStatus(String scenarioId) async {
     await Future.delayed(const Duration(milliseconds: 200));
     _userStatuses.remove(scenarioId);
     safePrint('Removed status for $scenarioId. Current statuses: $_userStatuses');
  }
}
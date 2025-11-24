// ファイルパス: lib/features/group_search/data/repositories/group_search_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/group_search/domain/repositories/group_search_repository.dart';

class GroupSearchRepositoryImpl implements GroupSearchRepository {
  static const String _kQueryName = 'findGroupScenarios';

  @override
  Future<List<String>> findGroupScenarios(List<String> friendIds) async {
    // GraphQLクエリの構築
    // 引数は [ID!]! なので、ダブルクォーテーションで囲んだ文字列の配列として渡す必要がある
    // final friendIdsString = jsonEncode(friendIds); // ex: ["user1", "user2"]
    
    // リテラル埋め込みではなく、GraphQL変数を使用するのがベストだが、
    // List<ID>の変数を渡すのがAmplify Flutterで少し複雑な場合があるため、
    // ここでは単純なString引数として渡す形ではなく、リストとして正しく渡す。
    
    const doc = r'''
      query FindGroupScenarios($friendIds: [ID!]!) {
        findGroupScenarios(friendIds: $friendIds)
      }
    ''';

    final request = GraphQLRequest<String>(
      document: doc,
      variables: {
        'friendIds': friendIds,
      },
    );

    try {
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        throw Exception('GraphQL Errors: ${response.errors.map((e) => e.message).join(', ')}');
      }

      final data = response.data;
      if (data == null) {
        throw Exception('Response data is null');
      }

      final Map<String, dynamic> jsonMap = jsonDecode(data);
      final String? resultJsonString = jsonMap[_kQueryName];

      if (resultJsonString == null) {
        return [];
      }

      // LambdaはJSON文字列のリストを返しているのでデコード
      final List<dynamic> resultList = jsonDecode(resultJsonString);
      return resultList.map((e) => e.toString()).toList();

    } catch (e) {
      safePrint('Error in findGroupScenarios: $e');
      rethrow;
    }
  }
}
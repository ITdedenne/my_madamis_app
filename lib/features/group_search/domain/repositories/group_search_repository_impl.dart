// ファイルパス: lib/features/group_search/domain/repositories/group_search_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';
import 'package:my_madamis_app/features/group_search/domain/repositories/group_search_repository.dart';

class GroupSearchRepositoryImpl implements GroupSearchRepository {
  static const String _kQueryName = 'findGroupScenarios';

  @override
  Future<List<GroupSearchResult>> findGroupScenarios(List<String> friendIds) async {
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

      // LambdaはJSON文字列のリストを返している
      final List<dynamic> resultList = jsonDecode(resultJsonString);
      
      return resultList.map((json) {
        if (json is Map<String, dynamic>) {
          return GroupSearchResult.fromJson(json);
        }
        return GroupSearchResult(scenarioId: json.toString());
      }).toList();

    } catch (e) {
      safePrint('Error in findGroupScenarios: $e');
      rethrow;
    }
  }
}
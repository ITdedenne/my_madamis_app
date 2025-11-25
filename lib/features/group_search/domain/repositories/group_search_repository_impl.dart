import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';
import 'package:my_madamis_app/features/group_search/domain/repositories/group_search_repository.dart';

class GroupSearchRepositoryImpl implements GroupSearchRepository {
  @override
  Future<List<GroupSearchResult>> findGroupScenarios(List<String> friendIds) async {
    const doc = r'''
      query FindGroupScenarios($friendIds: [ID!]!) {
        findGroupScenarios(friendIds: $friendIds)
      }
    ''';

    final request = GraphQLRequest<String>(
      document: doc,
      variables: {'friendIds': friendIds},
    );

    try {
      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors) throw Exception('GraphQL Errors: ${response.errors}');
      
      final data = response.data;
      if (data == null) throw Exception('Response data is null');

      final Map<String, dynamic> jsonMap = jsonDecode(data);
      final String? resultJsonString = jsonMap['findGroupScenarios'];

      if (resultJsonString == null) return [];

      final List<dynamic> list = jsonDecode(resultJsonString);
      return list.map((e) => GroupSearchResult.fromJson(e)).toList();
    } catch (e) {
      safePrint('Error: $e');
      rethrow;
    }
  }
}
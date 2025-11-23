// ファイルパス: lib/features/player_finder/data/repositories/player_finder_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/player_finder/domain/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class PlayerFinderRepositoryImpl implements PlayerFinderRepository {
  
  @override
  Future<List<User>> findUnplayedFriends(String scenarioId) async {
    const query = r'''
      query FindUnplayedFriends($scenarioId: String!) {
        findUnplayedFriends(scenarioId: $scenarioId)
      }
    ''';

    final request = GraphQLRequest<String>(
      document: query,
      variables: {'scenarioId': scenarioId},
    );

    final response = await Amplify.API.query(request: request).response;

    if (response.hasErrors) {
      throw Exception('Failed to find unplayed friends: ${response.errors}');
    }

    final jsonString = response.data;
    if (jsonString == null) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      safePrint('Error parsing findUnplayedFriends response: $e');
      return [];
    }
  }
}
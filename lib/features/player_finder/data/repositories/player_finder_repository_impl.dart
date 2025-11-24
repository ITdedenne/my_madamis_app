import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart'; // ★ 追加
import 'package:my_madamis_app/features/player_finder/data/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class PlayerFinderRepositoryImpl implements PlayerFinderRepository {
  static const String _kQueryKey = 'findUnplayedFriends';
  
  @override
  Future<List<SearchedUser>> findUnplayedFriends(String scenarioId) async {
    const query = r'''
      query FindUnplayedFriends($scenarioId: String!) {
        ''' + _kQueryKey + r'''(scenarioId: $scenarioId)
      }
    ''';
    
    final request = GraphQLRequest<String>(
      document: query,
      variables: {'scenarioId': scenarioId},
    );

    try {
      final response = await Amplify.API.query(request: request).response;
      
      if (response.hasErrors) {
        final errors = response.errors.map((e) => e.message).join(', ');
        throw Exception('GraphQL Errors: $errors');
      }

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Response data is null');
      }

      final Map<String, dynamic> outerMap = jsonDecode(responseData);
      final String? innerJsonString = outerMap[_kQueryKey];
      
      if (innerJsonString == null) {
        throw Exception('Key "$_kQueryKey" not found in response');
      }

      final dynamic decodedList = jsonDecode(innerJsonString);

      if (decodedList is! List) {
         throw Exception('Decoded JSON is not a List');
      }

      // ★ 変換ロジックを更新: JSONからwantsToPlayを取り出しSearchedUserを作成
      return decodedList.map((json) {
        if (json is Map<String, dynamic>) {
          // Userモデルの復元
          final user = User.fromJson(json);
          // 拡張フィールドの取得
          final wantsToPlay = json['wantsToPlay'] as bool? ?? false;
          
          return SearchedUser(user: user, wantsToPlay: wantsToPlay);
        }
        return null;
      }).whereType<SearchedUser>().toList();

    } catch (e, stackTrace) {
      safePrint('Error in findUnplayedFriends: $e');
      safePrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
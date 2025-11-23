// ファイルパス: lib/features/player_finder/data/repositories/player_finder_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/player_finder/domain/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class PlayerFinderRepositoryImpl implements PlayerFinderRepository {
  // 定数化: API定義と紐付いていることを明示
  static const String _kQueryKey = 'findUnplayedFriends';
  
  @override
  Future<List<User>> findUnplayedFriends(String scenarioId) async {
    // 文字列埋め込みを使用してクエリを作成
    const query = r'''
      query FindUnplayedFriends($scenarioId: String!) {
        ''' + _kQueryKey + r'''(scenarioId: $scenarioId)
      }
    ''';

    // decodePathを使用せず、手動パースで柔軟に対応
    final request = GraphQLRequest<String>(
      document: query,
      variables: {'scenarioId': scenarioId},
    );

    try {
      final response = await Amplify.API.query(request: request).response;

      // 1. GraphQLレベルのエラーチェック
      if (response.hasErrors) {
        final errors = response.errors.map((e) => e.message).join(', ');
        throw Exception('GraphQL Errors: $errors');
      }

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Response data is null');
      }

      // 2. レスポンスの解析 (Mapとしてデコード)
      final Map<String, dynamic> outerMap = jsonDecode(responseData);
      
      // 定数を使用して値を取得
      final String? innerJsonString = outerMap[_kQueryKey];
      
      if (innerJsonString == null) {
        throw Exception('Key "$_kQueryKey" not found in response');
      }

      // 3. JSON文字列のリストへのデコード
      final dynamic decodedList = jsonDecode(innerJsonString);

      if (decodedList is! List) {
         throw Exception('Decoded JSON is not a List');
      }

      // 4. Userモデルへの変換
      return decodedList.map((json) {
        if (json is Map<String, dynamic>) {
          return User.fromJson(json);
        }
        return null;
      }).whereType<User>().toList();

    } catch (e, stackTrace) {
      safePrint('Error in findUnplayedFriends: $e');
      safePrint('Stack trace: $stackTrace');
      
      // エラーを握りつぶさず再スローする (ViewModelでハンドリングするため)
      rethrow;
    }
  }
}
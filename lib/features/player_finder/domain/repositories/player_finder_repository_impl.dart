// ファイルパス: lib/features/player_finder/data/repositories/player_finder_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/player_finder/domain/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class PlayerFinderRepositoryImpl implements PlayerFinderRepository {
  
  @override
  Future<List<User>> findUnplayedFriends(String scenarioId) async {
    // Lambdaは JSON文字列 を返す仕様なので、戻り値は String
    const query = r'''
      query FindUnplayedFriends($scenarioId: String!) {
        findUnplayedFriends(scenarioId: $scenarioId)
      }
    ''';

    // decodePath は使わず、生のレスポンスを受け取って手動で解析します
    final request = GraphQLRequest<String>(
      document: query,
      variables: {'scenarioId': scenarioId},
    );

    try {
      final response = await Amplify.API.query(request: request).response;

      // 1. エラーチェック
      if (response.hasErrors) {
        safePrint('GraphQL Errors: ${response.errors}');
        throw Exception('Failed to find unplayed friends: ${response.errors}');
      }

      final responseData = response.data;
      if (responseData == null) {
        safePrint('Response data is null');
        return [];
      }

      safePrint('Raw Response Data: $responseData');

      // 2. レスポンスの解析 (二重デコード対応)
      // Amplifyのレスポンスは {"findUnplayedFriends": "[{...}, {...}]"} という形のJSON文字列で返ってくることが多い
      
      // まず全体をMapとしてデコード
      final Map<String, dynamic> outerMap = jsonDecode(responseData);
      
      // "findUnplayedFriends" キーの中身（これがLambdaが返したJSON文字列）を取り出す
      final String? innerJsonString = outerMap['findUnplayedFriends'];
      
      if (innerJsonString == null) {
        safePrint('Key "findUnplayedFriends" not found or null');
        return [];
      }

      // 3. Lambdaが返したJSON文字列をリストとしてデコード
      // "[{\"id\": ...}, ...]" -> List<dynamic>
      final dynamic decodedList = jsonDecode(innerJsonString);

      if (decodedList is! List) {
        safePrint('Decoded JSON is not a List: $decodedList');
        return [];
      }

      safePrint('Parsed List Length: ${decodedList.length}');

      // 4. Userモデルへ変換
      return decodedList.map((json) {
        // JSONパース時の安全策（念のためMapであることを確認）
        if (json is Map<String, dynamic>) {
          return User.fromJson(json);
        }
        return null; // 不正なデータは無視
      }).whereType<User>().toList(); // nullを除外してリスト化

    } catch (e, stackTrace) {
      safePrint('Error in findUnplayedFriends: $e');
      safePrint('Stack trace: $stackTrace');
      // 画面がクラッシュしないよう、エラー時は空リストを返す
      return [];
    }
  }
}
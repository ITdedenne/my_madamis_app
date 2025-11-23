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
      // ★★★ 修正箇所: decodePath を追加 ★★★
      // これがないと {"findUnplayedFriends": "[...]"} というMap全体の文字列が返ってきてしまい、
      // 下の jsonDecode で List として扱えずエラーになります。
      decodePath: 'findUnplayedFriends', 
    );

    try {
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        throw Exception('Failed to find unplayed friends: ${response.errors}');
      }

      final jsonString = response.data;
      if (jsonString == null) return [];

      // LambdaからはJSON形式の文字列が返ってくるので、それをデコードしてUserオブジェクトに変換
      final List<dynamic> list = jsonDecode(jsonString);
      
      // User.fromJsonを使ってモデルに変換
      return list.map((json) => User.fromJson(json)).toList();
      
    } catch (e) {
      safePrint('Error in findUnplayedFriends: $e');
      // エラー発生時は空リストを返す（画面には「見つかりません」と表示される）
      return [];
    }
  }
}
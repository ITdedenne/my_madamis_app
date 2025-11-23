// ファイルパス: lib/features/friends/data/repositories/friends_repository_impl.dart

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/core/constants/app_constants.dart'; // ★ 追加
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  
  Future<String> _getCurrentUserId() async {
    final attributes = await Amplify.Auth.fetchUserAttributes();
    return attributes
        .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.sub)
        .value;
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) return [];

    // publicUserId (7桁ID) での完全一致検索
    final publicIdRequest = ModelQueries.list(
      User.classType,
      where: User.PUBLICUSERID.eq(trimmedQuery),
    );
    
    // username での部分一致検索
    final usernameRequest = ModelQueries.list(
      User.classType,
      where: User.USERNAME.contains(trimmedQuery),
    );

    final responses = await Future.wait([
      Amplify.API.query(request: publicIdRequest).response,
      Amplify.API.query(request: usernameRequest).response,
    ]);

    final Set<User> results = {};
    
    for (var response in responses) {
      if (response.data != null) {
        results.addAll(response.data!.items.whereType<User>());
      }
    }
    
    // 自分自身は除外
    try {
      final myId = await _getCurrentUserId();
      results.removeWhere((u) => u.id == myId);
    } catch(_) {}

    return results.toList();
  }

  @override
  Future<void> followUser(String followedUserId) async {
    final currentUserId = await _getCurrentUserId();
    
    final relationship = UserRelationship(
      followingId: currentUserId,
      followedId: followedUserId,
    );
    
    final request = ModelMutations.create(relationship);
    final response = await Amplify.API.mutate(request: request).response;
    
    if (response.hasErrors) {
      // --- 暫定処置: 以下のエラーは無視して成功扱いにする (要件 3.4.6) ---
      final errorMessage = response.errors.first.message;
      
      // 1. 既にフォロー済み (重複エラー)
      final isAlreadyExists = errorMessage.contains('The conditional request failed');
      
      // 2. データ不整合による取得失敗 (ID不一致など)
      final isDataMismatch = errorMessage.contains('Cannot return null for non-nullable type');
      
      // 3. サーバー側のシリアライズエラー (日付不正など)
      final isSerializationError = errorMessage.contains('Can\'t serialize value') || 
                                   errorMessage.contains('Unable to serialize');

      if (isAlreadyExists || isDataMismatch || isSerializationError) {
        safePrint('⚠️ 暫定対応: エラーを無視して成功とみなします: $errorMessage');
        return; // エラーを投げずに終了
      }

      throw Exception('Follow failed: $errorMessage');
    }
  }

  @override
  Future<void> unfollowUser(String followedUserId) async {
    final currentUserId = await _getCurrentUserId();
    
    final relationship = UserRelationship(
      followingId: currentUserId, 
      followedId: followedUserId
    );
    
    final request = ModelMutations.delete(relationship);
    
    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      // --- 暫定処置: 以下のエラーは無視して成功扱いにする (要件 3.4.6) ---
      final errorMessage = response.errors.first.message;

      // 1. 既に削除済み、または存在しない
      final isNotExists = errorMessage.contains('The conditional request failed') || 
                          errorMessage.contains('DynamoDB:ConditionalCheckFailedException');
                          
      // 2. データ不整合による取得失敗
      final isDataMismatch = errorMessage.contains('Cannot return null for non-nullable type');

      if (isNotExists || isDataMismatch) {
         safePrint('⚠️ 暫定対応: エラーを無視して成功とみなします: $errorMessage');
         return;
      }

      throw Exception('Unfollow failed: $errorMessage');
    }
  }

  @override
  Future<List<User>> fetchFollowingUsers() async {
    final currentUserId = await _getCurrentUserId();
    final List<UserRelationship> allRelationships = [];

    // ★ 修正: limit: 1000 を廃止し、hasNextResultを用いたページネーションループを実装
    // 非機能要件 6.1.2 準拠
    var request = ModelQueries.list(
      UserRelationship.classType,
      where: UserRelationship.FOLLOWINGID.eq(currentUserId),
      limit: AppConstants.defaultPageSize, // 50件ずつ取得
    );

    try {
      while (true) {
        final response = await Amplify.API.query(request: request).response;
        
        if (response.hasErrors) {
          throw Exception('Failed to fetch following users: ${response.errors}');
        }

        final data = response.data;
        if (data == null) break;

        allRelationships.addAll(data.items.whereType<UserRelationship>());

        // 次のページがある場合はリクエストを更新してループ、なければ終了
        if (data.hasNextResult) {
          request = data.requestForNextResult!;
        } else {
          break;
        }
      }
    } catch (e) {
      // ループ中のエラーもここでキャッチ
      safePrint('Error during pagination fetch: $e');
      rethrow;
    }

    return allRelationships
        .map((r) => r.followedUser)
        .whereType<User>()
        .toList();
  }

  @override
  Future<int> getFollowingCount() async {
    final users = await fetchFollowingUsers();
    return users.length;
  }
}
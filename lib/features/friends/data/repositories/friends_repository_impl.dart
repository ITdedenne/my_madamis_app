// ファイルパス: lib/features/friends/data/repositories/friends_repository_impl.dart

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
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
    // 空白除去（前回の修正内容）
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

    // 並列実行
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
      // 重複エラー（既にフォロー済み）は無視して正常終了扱いにする（前回の修正内容）
      final isAlreadyExistsError = response.errors.any(
        (e) => e.message.contains('The conditional request failed')
      );

      if (isAlreadyExistsError) {
        safePrint('User relationship already exists. Treating as success.');
        return; 
      }

      throw Exception('Follow failed: ${response.errors.first.message}');
    }
  }

  @override
  Future<void> unfollowUser(String followedUserId) async {
    final currentUserId = await _getCurrentUserId();
    
    // 削除対象を特定するためのモデルを作成 (PKとSKを設定)
    final relationship = UserRelationship(
        followingId: currentUserId, 
        followedId: followedUserId
    );
    
    // ★ 修正ポイント: where句を削除し、シンプルな削除リクエストにする
    // キー(relationship)さえ合っていれば削除されます。
    // 権限チェック(@auth)はAmplify側で自動的に行われます。
    final request = ModelMutations.delete(relationship);
    
    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      // 「既に存在しない」エラーは無視して良い
      final isNotExistsError = response.errors.any(
        (e) => e.message.contains('The conditional request failed') || 
               e.message.contains('DynamoDB:ConditionalCheckFailedException')
      );
      
      if (isNotExistsError) {
         safePrint('Relationship not found or already deleted.');
         return;
      }

      safePrint('Unfollow error: ${response.errors}');
      throw Exception('Unfollow failed: ${response.errors.first.message}');
    }
  }

  @override
  Future<List<User>> fetchFollowingUsers() async {
    final currentUserId = await _getCurrentUserId();

    // PK(followingId)を直接クエリ
    final request = ModelQueries.list(
      UserRelationship.classType,
      where: UserRelationship.FOLLOWINGID.eq(currentUserId),
      limit: 1000, 
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.hasErrors) {
      throw Exception('Failed to fetch following users: ${response.errors}');
    }

    final relationships = response.data?.items.whereType<UserRelationship>() ?? [];
    
    // リレーション (@belongsTo) から User オブジェクトを抽出
    return relationships
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
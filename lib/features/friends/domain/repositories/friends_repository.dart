// ファイルパス: lib/features/friends/domain/repositories/friends_repository.dart

import 'package:my_madamis_app/models/ModelProvider.dart';

abstract class FriendsRepository {
  /// ユーザー名またはIDでユーザーを検索
  Future<List<User>> searchUsers(String query);

  /// ユーザーをフォロー
  Future<void> followUser(String followedUserId);

  /// フォロー解除
  Future<void> unfollowUser(String followedUserId);

  /// フォロー中のユーザー一覧取得
  Future<List<User>> fetchFollowingUsers();
  
  /// 現在のフォロー数を取得
  Future<int> getFollowingCount();
}
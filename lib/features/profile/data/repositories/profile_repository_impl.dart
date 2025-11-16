// ファイルパス: lib/features/profile/data/repositories/profile_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';

// ★ 追加: Amplify モデルを参照するために、モデルプロバイダーをインポート
import 'package:my_madamis_app/models/ModelProvider.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  
  // GraphQL Mutation (Lambda) を呼び出すためのドキュメント
  static const _updateUserProfileMutation = r'''
    mutation UpdateUserProfile($username: String!, $bio: String) {
      updateUserProfile(username: $username, bio: $bio)
    }
  ''';
  
  // ★ 修正箇所: 存在しないフィールド 'twitterld' や 'DynamoDB' を削除
  static const _getUserQuery = r'''
    query GetUser($id: ID!) {
      getUser(id: $id) {
        id
        username
        bio
        publicUserId
      }
    }
  ''';

  // ★ 追加: 現在認証済みのユーザーID (Cognito Sub ID) を取得するヘルパー関数
  Future<String> _getCurrentUserId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return attributes
          .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.sub) 
          .value;
    } on Exception catch (e) {
       safePrint('Failed to get current userId: $e');
       throw Exception('Authentication required to access user data.');
    }
  }

  @override
  Future<UserProfile> fetchUserProfile() async {
    final userId = await _getCurrentUserId();
    
    // 1. DynamoDB から User モデルを GraphQL Query で取得 (PK = Sub ID)
    final request = GraphQLRequest<User>(
      document: _getUserQuery,
      modelType: User.classType,
      variables: {
        'id': userId, 
      },
      decodePath: 'getUser',
      authorizationMode: APIAuthorizationType.userPools,
    );

    final response = await Amplify.API.query(request: request).response;

    if (response.data == null || response.hasErrors) {
      safePrint('GraphQL Error fetching profile: ${response.errors}');
      // エラー処理を改善
      throw Exception('Failed to fetch user profile: ${response.errors.map((e) => e.message).join(", ")}');
    }
    
    final userModel = response.data!;
    
    // 2. 取得した User モデルから UserProfile エンティティを構築
    // twitterId は現在スキーマから削除済みのため、空文字として扱う
    return UserProfile(
      username: userModel.username, 
      bio: userModel.bio ?? '', 
      twitterId: '', 
    );
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final request = GraphQLRequest(
        document: _updateUserProfileMutation,
        variables: {
          'username': profile.username,
          'bio': profile.bio,
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        // Lambda の実行が成功し、Lambda がエラー JSON を返した場合の対応
        if (response.data != null) {
            try {
                final body = jsonDecode(response.data!);
                if (body['updateUserProfile'] != null && body['updateUserProfile']['error'] != null) {
                    throw Exception(body['updateUserProfile']['error']);
                }
            } catch (_) {
                // JSON パース失敗または想定外の形式
            }
        }
        
        throw Exception('GraphQL Mutation Error: ${response.errors.map((e) => e.message).join(", ")}');
      }
      
    } on Exception catch (e) {
      safePrint('Failed to update profile via Lambda: $e');
      rethrow;
    }
  }
}
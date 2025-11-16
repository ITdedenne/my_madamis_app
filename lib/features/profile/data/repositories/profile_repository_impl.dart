// ファイルパス: lib/features/profile/data/repositories/profile_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  
  // GraphQL Mutation (Lambda) を呼び出すためのドキュメント
  // ★ 修正箇所: @function ディレクティブを削除し、標準形式にする
  static const _updateUserProfileMutation = r'''
    mutation UpdateUserProfile($username: String!, $bio: String) {
      updateUserProfile(username: $username, bio: $bio)
    }
  ''';


  @override
  Future<UserProfile> fetchUserProfile() async {
    // Note: DynamoDB から bio/twitterId を取得するロジックは、まだ実装していません。
    // 今は Cognito から取得できる情報のみに制限します。
    final attributes = await Amplify.Auth.fetchUserAttributes();

    final username = attributes
        .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.preferredUsername,
            orElse: () => const AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: ''))
        .value;
    
    // DynamoDB からのデータ取得が未実装のため、一旦空文字を返す
    const bio = ''; 
    const twitterId = ''; 

    return UserProfile(username: username, bio: bio, twitterId: twitterId);
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
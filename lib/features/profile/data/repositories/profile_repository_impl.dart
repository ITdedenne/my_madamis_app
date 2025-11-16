// ファイルパス: lib/features/profile/data/repositories/profile_repository_impl.dart

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  
  // GraphQL Mutation (Lambda) を呼び出すためのドキュメント
  static const _updateUserProfileMutation = r'''
    mutation UpdateUserProfile($username: String!, $bio: String) {
      updateUserProfile(username: $username, bio: $bio)
        @function(name: "updateUserProfile-${env}") {
        message
        username
        bio
      }
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
    // ★★★ 修正箇所: Cognito 直接更新から GraphQL Mutation (Lambda) 呼び出しへ切り替え (5.2.5) ★★★
    try {
      final request = GraphQLRequest(
        document: _updateUserProfileMutation,
        variables: {
          'username': profile.username,
          'bio': profile.bio,
          // twitterId は Lambda 側で処理しないため、GraphQL Mutation の引数には含めない
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        throw Exception('GraphQL Error: ${response.errors.map((e) => e.message).join(", ")}');
      }

      final body = jsonDecode(response.data!);
      final lambdaResponse = body['updateUserProfile'];
      
      if (lambdaResponse != null && lambdaResponse['error'] != null) {
        throw Exception(lambdaResponse['error']);
      }
      
    } on Exception catch (e) {
      safePrint('Failed to update profile via Lambda: $e');
      rethrow;
    }
  }
}
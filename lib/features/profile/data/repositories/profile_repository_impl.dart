// ファイルパス: lib/features/profile/data/repositories/profile_repository_impl.dart

import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<UserProfile> fetchUserProfile() async {
    final attributes = await Amplify.Auth.fetchUserAttributes();

    final username = attributes
        .firstWhere((a) => a.userAttributeKey == AuthUserAttributeKey.preferredUsername,
            orElse: () => const AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: ''))
        .value;
    final bio = attributes
        .firstWhere((a) => a.userAttributeKey == const CognitoUserAttributeKey.custom('bio'),
            // ▼▼▼ ここのタイプミスを修正しました ▼▼▼
            orElse: () => const AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.custom('bio'), value: ''))
        .value;
    final twitterId = attributes
        .firstWhere((a) => a.userAttributeKey == const CognitoUserAttributeKey.custom('twitter_id'),
            // ▼▼▼ ここのタイプミスを修正しました ▼▼▼
            orElse: () => const AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.custom('twitter_id'), value: ''))
        .value;

    return UserProfile(username: username, bio: bio, twitterId: twitterId);
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final attributesToUpdate = [
      AuthUserAttribute(
        userAttributeKey: AuthUserAttributeKey.preferredUsername,
        value: profile.username,
      ),
      AuthUserAttribute(
        userAttributeKey: const CognitoUserAttributeKey.custom('bio'),
        value: profile.bio,
      ),
      AuthUserAttribute(
        userAttributeKey: const CognitoUserAttributeKey.custom('twitter_id'),
        value: profile.twitterId,
      ),
    ];
    await Amplify.Auth.updateUserAttributes(attributes: attributesToUpdate);
  }
}
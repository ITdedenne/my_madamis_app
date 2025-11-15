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
    
    // 要件 6.3.3: Cognitoカスタム属性の廃止に伴い、取得処理を修正 (DynamoDBへの移行が完了するまで空文字を返す)
    const bio = ''; 
    const twitterId = ''; 

    return UserProfile(username: username, bio: bio, twitterId: twitterId);
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final attributesToUpdate = [
      AuthUserAttribute(
        userAttributeKey: AuthUserAttributeKey.preferredUsername,
        value: profile.username,
      ),
      // 要件 6.3.3: Cognitoカスタム属性の廃止に伴い、bio/twitterIdの更新を削除
    ];
    await Amplify.Auth.updateUserAttributes(attributes: attributesToUpdate);
  }
}
// ファイルパス: lib/features/profile/domain/entities/user_profile.dart

class UserProfile {
  // ▼▼▼ finalキーワードを追加し、プロパティを正しく定義しました ▼▼▼
  final String username;
  final String bio;
  final String twitterId;

  UserProfile({
    required this.username,
    this.bio = '',
    this.twitterId = '',
  });

  UserProfile copyWith({
    String? username,
    String? bio,
    String? twitterId,
  }) {
    return UserProfile(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      twitterId: twitterId ?? this.twitterId,
    );
  }
}
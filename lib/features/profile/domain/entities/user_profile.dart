// ファイルパス: lib/features/profile/domain/entities/user_profile.dart

import 'package:equatable/equatable.dart'; 

class UserProfile extends Equatable { 
  final String? publicUserId; // ★ 修正: String? (Null許容型) に変更
  final String username;
  final String bio;
  final String twitterId;

  const UserProfile({
    this.publicUserId, // ★ 修正: オプショナル引数に変更
    required this.username,
    this.bio = '',
    this.twitterId = '',
  });

  UserProfile copyWith({
    String? publicUserId, // ★ 修正: publicUserId を追加
    String? username,
    String? bio,
    String? twitterId,
  }) {
    return UserProfile(
      publicUserId: publicUserId ?? this.publicUserId, // ★ 修正: publicUserId を追加
      username: username ?? this.username,
      bio: bio ?? this.bio,
      twitterId: twitterId ?? this.twitterId,
    );
  }

  @override
  List<Object?> get props => [publicUserId, username, bio, twitterId]; // ★ 修正: publicUserId を props に追加
}
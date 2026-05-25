// ファイルパス: lib/features/profile/domain/entities/user_profile.dart

import 'package:equatable/equatable.dart'; 

class UserProfile extends Equatable { 
  final String? publicUserId;
  final String username;
  final String bio;
  final String twitterId;

  const UserProfile({
    this.publicUserId,
    required this.username,
    this.bio = '',
    this.twitterId = '',
  });

  UserProfile copyWith({
    String? publicUserId,
    String? username,
    String? bio,
    String? twitterId,
  }) {
    return UserProfile(
      publicUserId: publicUserId ?? this.publicUserId,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      twitterId: twitterId ?? this.twitterId,
    );
  }

  @override
  List<Object?> get props => [publicUserId, username, bio, twitterId];
}
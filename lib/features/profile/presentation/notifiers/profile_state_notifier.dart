// ファイルパス: lib/features/profile/presentation/notifiers/profile_state_notifier.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';

// プロフィール画面の状態
enum ProfileStatus { loading, loaded, error }

// 状態管理クラス
class ProfileState {
  final ProfileStatus status;
  final String? username;
  final String? bio; // 自己紹介文
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.loading,
    this.username,
    this.bio,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? username,
    String? bio,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// StateNotifierProvider
final profileStateNotifierProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref.watch(authRepositoryProvider))..loadCurrentUser();
});


// StateNotifier
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final AuthRepository _authRepository;

  ProfileStateNotifier(this._authRepository) : super(const ProfileState());

  /// 現在のユーザー情報を取得して状態を更新します。
  Future<void> loadCurrentUser() async {
    try {
      state = state.copyWith(status: ProfileStatus.loading);
      final attributes = await _authRepository.fetchCurrentUserAttributes();
      
      final username = attributes[AuthUserAttributeKey.preferredUsername];
      // 自己紹介は 'custom:bio' というカスタム属性から取得します。
      // ※事前にAmplify Admin UIやCLIでCognitoのUser Poolにこの属性を追加しておく必要があります。
      final bio = attributes[const CognitoUserAttributeKey.custom('bio')];

      state = state.copyWith(
        status: ProfileStatus.loaded,
        username: username,
        bio: bio,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'ユーザー情報の取得に失敗しました: $e',
      );
    }
  }
}
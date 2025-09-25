// ファイルパス: lib/features/profile/presentation/notifiers/profile_state_notifier.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';

enum ProfileStatus { loading, loaded, error }
enum UpdateStatus { initial, success, error }

class ProfileState {
  final ProfileStatus status;
  final String? username;
  final String? bio;
  final String? twitterId; // 追加
  final String? errorMessage;
  final UpdateStatus updateStatus;

  const ProfileState({
    this.status = ProfileStatus.loading,
    this.username,
    this.bio,
    this.twitterId, // 追加
    this.errorMessage,
    this.updateStatus = UpdateStatus.initial,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? username,
    String? bio,
    String? twitterId, // 追加
    String? errorMessage,
    UpdateStatus? updateStatus,
  }) {
    return ProfileState(
      status: status ?? this.status,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      twitterId: twitterId ?? this.twitterId, // 追加
      errorMessage: errorMessage ?? this.errorMessage,
      updateStatus: updateStatus ?? this.updateStatus,
    );
  }
}

final profileStateNotifierProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref)..loadCurrentUser();
});

class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  late final AuthRepository _authRepository;

  ProfileStateNotifier(this._ref) : super(const ProfileState()) {
    _authRepository = _ref.read(authRepositoryProvider);
  }

  Future<void> loadCurrentUser() async {
    try {
      state = state.copyWith(status: ProfileStatus.loading);
      final attributes = await _authRepository.fetchCurrentUserAttributes();
      
      final username = attributes[AuthUserAttributeKey.preferredUsername];
      final bio = attributes[const CognitoUserAttributeKey.custom('bio')];
      final twitterId = attributes[const CognitoUserAttributeKey.custom('twitter_id')]; // 追加

      state = state.copyWith(
        status: ProfileStatus.loaded,
        username: username,
        bio: bio,
        twitterId: twitterId, // 追加
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'ユーザー情報の取得に失敗しました: $e',
      );
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String bio,
    required String twitterId, // 追加
  }) async {
    try {
      await _authRepository.updateUserAttributes(
        username: username,
        bio: bio,
        twitterId: twitterId, // 追加
      );
      _ref.read(authStateNotifierProvider.notifier).updateUsername(username);
      
      state = state.copyWith(
        username: username,
        bio: bio,
        twitterId: twitterId, // 追加
        updateStatus: UpdateStatus.success,
      );
      return true;
    } catch (e) {
      state = state.copyWith(updateStatus: UpdateStatus.error);
      return false;
    }
  }

  void resetUpdateStatus() {
    state = state.copyWith(updateStatus: UpdateStatus.initial);
  }
}
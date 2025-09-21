// ファイルパス: lib/features/profile/presentation/notifiers/profile_state_notifier.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';

// プロフィール画面の状態
enum ProfileStatus { loading, loaded, error }
// 保存処理の状態
enum UpdateStatus { initial, success, error }

// 状態管理クラス
class ProfileState {
  final ProfileStatus status;
  final String? username;
  final String? bio;
  final String? errorMessage;
  final UpdateStatus updateStatus;

  const ProfileState({
    this.status = ProfileStatus.loading,
    this.username,
    this.bio,
    this.errorMessage,
    this.updateStatus = UpdateStatus.initial,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? username,
    String? bio,
    String? errorMessage,
    UpdateStatus? updateStatus,
  }) {
    return ProfileState(
      status: status ?? this.status,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      errorMessage: errorMessage ?? this.errorMessage,
      updateStatus: updateStatus ?? this.updateStatus,
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

  /// ログイン後、最初にユーザー情報を読み込みます。
  Future<void> loadCurrentUser() async {
    try {
      state = state.copyWith(status: ProfileStatus.loading);
      final attributes = await _authRepository.fetchCurrentUserAttributes();
      
      final username = attributes[AuthUserAttributeKey.preferredUsername];
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

  /// プロフィール情報を更新します。
  Future<bool> updateProfile({
    required String username,
    required String bio,
  }) async {
    try {
      await _authRepository.updateUserAttributes(
        username: username,
        bio: bio,
      );
      state = state.copyWith(
        username: username,
        bio: bio,
        updateStatus: UpdateStatus.success,
      );
      return true;
    } catch (e) {
      state = state.copyWith(updateStatus: UpdateStatus.error);
      return false;
    }
  }

  /// 更新後のメッセージ表示を一度だけに限定するため、ステータスをリセットします。
  void resetUpdateStatus() {
    state = state.copyWith(updateStatus: UpdateStatus.initial);
  }
}
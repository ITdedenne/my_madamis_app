// ファイルパス: lib/features/profile/presentation/notifiers/profile_state_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';

// プロフィール画面の状態
enum ProfileStatus { loading, loaded, error }
// ▼▼▼ 1. 保存処理の状態を追加 ▼▼▼
enum UpdateStatus { initial, success, error }

// 状態管理クラス
class ProfileState {
  final ProfileStatus status;
  final String? username;
  final String? bio;
  final String? errorMessage;
  // ▼▼▼ 2. 保存状態のプロパティを追加 ▼▼▼
  final UpdateStatus updateStatus;

  const ProfileState({
    this.status = ProfileStatus.loading,
    this.username,
    this.bio,
    this.errorMessage,
    // ▼▼▼ 3. 初期値を追加 ▼▼▼
    this.updateStatus = UpdateStatus.initial,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? username,
    String? bio,
    String? errorMessage,
    // ▼▼▼ 4. copyWith に追加 ▼▼▼
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

// StateNotifierProvider (変更なし)
final profileStateNotifierProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref.watch(authRepositoryProvider))..loadCurrentUser();
});


// StateNotifier
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final AuthRepository _authRepository;

  ProfileStateNotifier(this._authRepository) : super(const ProfileState());

  // loadCurrentUser メソッド (変更なし)
  Future<void> loadCurrentUser() async {
    // ... 既存のコード ...
  }

  // ▼▼▼ 5. updateProfileメソッドを修正 ▼▼▼
  /// ユーザーのプロフィール情報（ユーザー名、自己紹介）を更新します。
  /// 成功した場合は true, 失敗した場合は false を返します。
  Future<bool> updateProfile({
    required String username,
    required String bio,
  }) async {
    try {
      await _authRepository.updateUserAttributes(
        username: username,
        bio: bio,
      );
      // ローカルの状態も更新し、成功ステータスをセット
      state = state.copyWith(
        username: username,
        bio: bio,
        updateStatus: UpdateStatus.success,
      );
      return true;
    } catch (e) {
      // エラーステータスをセット
      state = state.copyWith(updateStatus: UpdateStatus.error);
      return false;
    }
  }

  // ▼▼▼ 6. 保存状態をリセットするメソッドを追加 ▼▼▼
  void resetUpdateStatus() {
    state = state.copyWith(updateStatus: UpdateStatus.initial);
  }
}
// ファイルパス: lib/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/usecases/update_user_profile_usecase.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

enum EditProfileStatus { initial, loading, success, error }

class EditProfileState {
  final EditProfileStatus status;
  final String? errorMessage;

  EditProfileState({
    this.status = EditProfileStatus.initial,
    this.errorMessage,
  });

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? errorMessage,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final editProfileViewModelProvider =
    StateNotifierProvider<EditProfileViewModel, EditProfileState>((ref) {
  final useCase = UpdateUserProfileUseCase(ref.watch(profileRepositoryProvider));
  return EditProfileViewModel(useCase, ref);
});

class EditProfileViewModel extends StateNotifier<EditProfileState> {
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final Ref _ref;

  EditProfileViewModel(this._updateUserProfileUseCase, this._ref) : super(EditProfileState());

  Future<void> updateProfile({
    String? publicUserId, // ★ 修正: String? (Null許容型) に変更
    required String username,
    required String bio,
    // twitterId は UI から渡されるが、現在はバックエンドに送信しない
    required String twitterId, 
  }) async {
    state = state.copyWith(status: EditProfileStatus.loading);
    try {
      // ★ 修正箇所: publicUserId を渡してエンティティを構築
      final profile = UserProfile(
        publicUserId: publicUserId,
        username: username, 
        bio: bio, 
        twitterId: ''
      ); 
      await _updateUserProfileUseCase(profile);
      
      // グローバルなユーザー名状態も更新
      _ref.read(authStateNotifierProvider.notifier).updateUsername(username);
      
      // プロフィール表示画面のViewModelの状態を直接更新する
      _ref.read(profileViewModelProvider.notifier).updateStateWithNewProfile(profile);
      
      state = state.copyWith(status: EditProfileStatus.success);
    } catch (e) {
      state = state.copyWith(status: EditProfileStatus.error, errorMessage: e.toString());
    }
  }
}
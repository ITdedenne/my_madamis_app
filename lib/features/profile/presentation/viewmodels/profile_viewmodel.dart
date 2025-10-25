// ファイルパス: lib/features/profile/presentation/viewmodels/profile_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final useCase = GetUserProfileUseCase(ref.watch(profileRepositoryProvider));
  return ProfileViewModel(useCase);
});


class ProfileViewModel extends StateNotifier<ProfileState> {
  final GetUserProfileUseCase _getUserProfileUseCase;

  ProfileViewModel(this._getUserProfileUseCase) : super(ProfileState()) {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final userProfile = await _getUserProfileUseCase();
      state = state.copyWith(status: ProfileStatus.loaded, profile: userProfile);
    } catch (e) {
      state = state.copyWith(status: ProfileStatus.error, errorMessage: e.toString());
    }
  }

  /// 編集画面から呼び出される、ローカルStateを直接更新するためのメソッド
  void updateStateWithNewProfile(UserProfile newProfile) {
    state = state.copyWith(profile: newProfile);
  }
}
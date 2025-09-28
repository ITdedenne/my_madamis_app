// ファイルパス: lib/features/auth/presentation/viewmodels/create_profile_viewmodel.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_up_usecase.dart';

enum CreateProfileStatus { initial, loading, requiresConfirmation, error }

class CreateProfileState {
  final CreateProfileStatus status;
  final String? errorMessage;
  final String? lastPassword; // 登録時のパスワードを保持

  CreateProfileState({
    this.status = CreateProfileStatus.initial, 
    this.errorMessage, 
    this.lastPassword,
  });

  CreateProfileState copyWith({
    CreateProfileStatus? status, 
    String? errorMessage, 
    String? lastPassword,
  }) {
    return CreateProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastPassword: lastPassword ?? this.lastPassword,
    );
  }
}

final createProfileViewModelProvider =
    StateNotifierProvider<CreateProfileViewModel, CreateProfileState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  // ★修正: SignUpUseCaseとViewModelのコンストラクタは位置引数を使用する
  final signUpUseCase = SignUpUseCase(authRepository); 
  return CreateProfileViewModel(
    signUpUseCase, // 位置引数1
    authRepository, // 位置引数2
  );
});

class CreateProfileViewModel extends StateNotifier<CreateProfileState> {
  final SignUpUseCase _signUpUseCase;
  final AuthRepository _authRepository;

  // ★修正: コンストラクタを既存の定義（位置引数）に戻す
  CreateProfileViewModel(this._signUpUseCase, this._authRepository) : super(CreateProfileState());

  Future<void> signUp({
    required String email,
    required String password,
    required String username, // CreateProfilePageに合わせるため必須引数として残す
    required String bio,
    required String twitterId,
  }) async {
    state = state.copyWith(status: CreateProfileStatus.loading);
    try {
      // ★修正: SignUpUseCase.call()を新しいシグネチャに合わせる
      await _signUpUseCase.call(
        email: email,
        password: password,
        profile: UserProfile( // UserProfileとしてまとめて渡す
          username: username,
          bio: bio,
          twitterId: twitterId,
        ),
      );
      
      state = state.copyWith(
        status: CreateProfileStatus.requiresConfirmation,
        lastPassword: password, // パスワードを状態に保持
      );
    } on UsernameExistsException {
      await _authRepository.resendSignUpCode(username: email);
      
      state = state.copyWith(
        status: CreateProfileStatus.requiresConfirmation,
        lastPassword: password, // パスワードを状態に保持
      );
    } catch (e) {
      state = state.copyWith(
        status: CreateProfileStatus.error, errorMessage: e.toString());
    }
  }
}
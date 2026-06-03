// ファイルパス: lib/features/auth/presentation/viewmodels/create_profile_viewmodel.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart'; 

enum CreateProfileStatus { initial, loading, requiresConfirmation, success, error }

class CreateProfileState {
  final CreateProfileStatus status;
  final String? errorMessage;
  final String? lastPassword;
  final String? username;

  CreateProfileState({
    this.status = CreateProfileStatus.initial, 
    this.errorMessage,
    this.lastPassword,
    this.username,
  });

  CreateProfileState copyWith({
    CreateProfileStatus? status, 
    String? errorMessage, 
    String? lastPassword,
    String? username,
  }) {
    return CreateProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastPassword: lastPassword ?? this.lastPassword,
      username: username ?? this.username,
    );
  }
}

final createProfileViewModelProvider =
    StateNotifierProvider<CreateProfileViewModel, CreateProfileState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final signInUseCase = SignInUseCase(authRepository);
  final signUpUseCase = SignUpUseCase(authRepository); 
  final authRepo = ref.watch(authRepositoryProvider);
  return CreateProfileViewModel(signUpUseCase, authRepo, signInUseCase);
});

class CreateProfileViewModel extends StateNotifier<CreateProfileState> {
  final SignUpUseCase _signUpUseCase;
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;

  CreateProfileViewModel(this._signUpUseCase, this._authRepository, this._signInUseCase) : super(CreateProfileState());

    void resetStateToInitial() {
    state = state.copyWith(status: CreateProfileStatus.initial, errorMessage: null);
  }

  Future<void> _handleUserAlreadyConfirmed(String email, String password) async {
    // ユーザーが既に確認済みの場合、サインアップ/再送は失敗する。直ちにサインインを試みる。
    try {
      final username = await _signInUseCase(email, password);
      // サインイン成功
      state = state.copyWith(status: CreateProfileStatus.success, username: username);
    } catch (e) {
      // サインインにも失敗した場合（パスワード間違いなど）
      state = state.copyWith(
        status: CreateProfileStatus.error, 
        errorMessage: 'ユーザーは登録済みですが、サインインに失敗しました。パスワードを確認してください。',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    state = state.copyWith(status: CreateProfileStatus.loading, errorMessage: null);
    
    final profile = UserProfile(
      username: username,
      bio: bio ?? '', 
      twitterId: twitterId ?? '',
      
    );
    
    try {
      await _signUpUseCase.call(
        email: email,
        password: password,
        profile: profile, 
      );
      
      // 新規登録成功時: パスワードを保持して確認画面へ遷移
      state = state.copyWith(
        status: CreateProfileStatus.requiresConfirmation,
        lastPassword: password, 
      );
    } on UsernameExistsException {
      // ユーザーが既に存在する場合: コード再送ロジックを個別のtry-catchで囲む
      try {
        await _authRepository.resendSignUpCode(username: email);
        state = state.copyWith(
          status: CreateProfileStatus.requiresConfirmation,
          lastPassword: password, 
        );
      } catch (resendError) { 
        if (resendError.toString().contains('User is already confirmed')) {
          // 既に確認済みと判明した場合、自動ログインに切り替える
          await _handleUserAlreadyConfirmed(email, password);
        } else {
          // その他の再送エラー
          state = state.copyWith(
            status: CreateProfileStatus.error, 
            errorMessage: '確認コードの再送に失敗しました: ${resendError.toString()}',
          );
        }
      }
    }
    catch (e) {
      // その他のエラー時、ローディングを解除しエラーメッセージを表示
      state = state.copyWith(
          status: CreateProfileStatus.error, errorMessage: e.toString());
    }
  }
}
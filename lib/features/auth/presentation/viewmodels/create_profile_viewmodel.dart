// ファイルパス: lib/features/auth/presentation/viewmodels/create_profile_viewmodel.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart'; // UserProfileのimportは必須です

enum CreateProfileStatus { initial, loading, requiresConfirmation, error }

class CreateProfileState {
  final CreateProfileStatus status;
  final String? errorMessage;
  final String? lastPassword; // パスワード保持のフィールド

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
  final signUpUseCase = SignUpUseCase(authRepository); // 位置引数
  final authRepo = ref.watch(authRepositoryProvider);
  return CreateProfileViewModel(signUpUseCase, authRepo); // 位置引数
});

class CreateProfileViewModel extends StateNotifier<CreateProfileState> {
  final SignUpUseCase _signUpUseCase;
  final AuthRepository _authRepository;

  CreateProfileViewModel(this._signUpUseCase, this._authRepository) : super(CreateProfileState());

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    state = state.copyWith(status: CreateProfileStatus.loading, errorMessage: null);
    
    // ★修正ポイント1: UserProfileエンティティを作成する
    final profile = UserProfile(
      username: username,
      // bioやtwitterIdはnullの場合はUserProfileのデフォルト値（''）が使用されます
      bio: bio ?? '', 
      twitterId: twitterId ?? '',
    );
    
    try {
      // ★修正ポイント2: SignUpUseCaseのシグネチャに合わせてUserProfileを渡す
      await _signUpUseCase.call(
        email: email,
        password: password,
        profile: profile, // 必須の'profile'引数を渡す
      );
      
      // 新規登録成功時: パスワードを保持して確認画面へ遷移
      state = state.copyWith(
        status: CreateProfileStatus.requiresConfirmation,
        lastPassword: password, 
      );
    } on UsernameExistsException {
      // ユーザーが既に存在する場合: コードを再送し、パスワードを保持して確認画面へ遷移
      await _authRepository.resendSignUpCode(username: email);
      state = state.copyWith(
        status: CreateProfileStatus.requiresConfirmation,
        lastPassword: password, 
      );
    }
    catch (e) {
      // その他のエラー時
      state = state.copyWith(
          status: CreateProfileStatus.error, errorMessage: e.toString());
    }
  }
}
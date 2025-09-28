// ファイルパス: lib/features/auth/presentation/viewmodels/create_profile_viewmodel.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum CreateProfileStatus { initial, loading, requiresConfirmation, error }

class CreateProfileState {
  final CreateProfileStatus status;
  final String? errorMessage;

  CreateProfileState({this.status = CreateProfileStatus.initial, this.errorMessage});

  CreateProfileState copyWith({CreateProfileStatus? status, String? errorMessage}) {
    return CreateProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final createProfileViewModelProvider =
    StateNotifierProvider<CreateProfileViewModel, CreateProfileState>((ref) {
  final signUpUseCase = SignUpUseCase(ref.watch(authRepositoryProvider));
  // ユーザー重複時のコード再送のためにリポジトリも直接利用
  final authRepository = ref.watch(authRepositoryProvider);
  return CreateProfileViewModel(signUpUseCase, authRepository);
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
    state = state.copyWith(status: CreateProfileStatus.loading);
    try {
      await _signUpUseCase(
        email: email,
        password: password,
        username: username,
        bio: bio,
        twitterId: twitterId,
      );
      state = state.copyWith(status: CreateProfileStatus.requiresConfirmation);
    } on UsernameExistsException {
      // ユーザーが既に存在する場合はコードを再送して確認画面へ
      await _authRepository.resendSignUpCode(username: email);
      state = state.copyWith(status: CreateProfileStatus.requiresConfirmation);
    }
    catch (e) {
      state = state.copyWith(status: CreateProfileStatus.error, errorMessage: e.toString());
    }
  }
}
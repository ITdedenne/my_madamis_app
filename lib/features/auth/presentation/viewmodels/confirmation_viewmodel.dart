// ファイルパス: lib/features/auth/presentation/viewmodels/confirmation_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:my_madamis_app/providers.dart';

enum ConfirmationStatus { initial, loading, success, error }

class ConfirmationState {
  final ConfirmationStatus status;
  final String? errorMessage;

  ConfirmationState({
    this.status = ConfirmationStatus.initial,
    this.errorMessage,
  });

  ConfirmationState copyWith({ConfirmationStatus? status, String? errorMessage, String? username}) {
    return ConfirmationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final confirmationViewModelProvider =
    StateNotifierProvider<ConfirmationViewModel, ConfirmationState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final signInUseCase = SignInUseCase(authRepository);
  return ConfirmationViewModel(authRepository, signInUseCase);
});

class ConfirmationViewModel extends StateNotifier<ConfirmationState> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  ConfirmationViewModel(this._authRepository, this._signInUseCase) : super(ConfirmationState());

  Future<void> confirmSignUp({
    required String email,
    required String password,
    required String confirmationCode,
  }) async {
    state = state.copyWith(status: ConfirmationStatus.loading);
    try {
      await _authRepository.confirmSignUp(username: email, confirmationCode: confirmationCode);
      // 確認が成功したら自動ログイン
      await _signInUseCase(email, password);
       state = state.copyWith(status: ConfirmationStatus.success);
    } catch (e) {
      state = state.copyWith(status: ConfirmationStatus.error, errorMessage: e.toString());
    }
  }
}
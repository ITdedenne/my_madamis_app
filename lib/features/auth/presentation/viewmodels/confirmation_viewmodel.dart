// ファイルパス: lib/features/auth/presentation/viewmodels/confirmation_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; 

enum ConfirmationStatus { initial, loading, success, error }

class ConfirmationState {
  final ConfirmationStatus status;
  final String? errorMessage;
  final String? authenticatedUsername;

  ConfirmationState({
    this.status = ConfirmationStatus.initial,
    this.errorMessage,
    this.authenticatedUsername,
  });

  ConfirmationState copyWith({
    ConfirmationStatus? status, 
    String? errorMessage,
    String? authenticatedUsername,
  }) {
    return ConfirmationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      authenticatedUsername: authenticatedUsername ?? this.authenticatedUsername,
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
    state = state.copyWith(status: ConfirmationStatus.loading, errorMessage: null);
    try {
      try {
        await _authRepository.confirmSignUp(username: email, confirmationCode: confirmationCode);
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('user cannot be confirmed') || 
            errorMessage.contains('user is already confirmed') ||
            errorMessage.contains('confirmed')) {
          safePrint('User is already confirmed, proceeding to sign in.');
        } else {
          rethrow; 
        }
      }
      
      final username = await _signInUseCase(email, password);
       
      state = state.copyWith(
        status: ConfirmationStatus.success,
        authenticatedUsername: username,
      );

    } catch (e) {
      state = state.copyWith(status: ConfirmationStatus.error, errorMessage: e.toString());
    }
  }
}
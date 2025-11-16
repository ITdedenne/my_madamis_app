// ファイルパス: lib/features/auth/presentation/viewmodels/confirmation_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // ★ safePrint のためにインポート

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
    state = state.copyWith(status: ConfirmationStatus.loading, errorMessage: null);
    try {
      
      // --- ▼▼▼ 修正箇所 ▼▼▼ ---
      try {
        // 1. まず確認コードの送信を試みる
        await _authRepository.confirmSignUp(username: email, confirmationCode: confirmationCode);
      } catch (e) {
        // 2. もしエラーが「既に確認済み」であった場合は、
        //    (ダブルクリックや再試行などの理由で)
        //    エラーを無視してログイン処理に進む
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('user cannot be confirmed') || 
            errorMessage.contains('user is already confirmed') ||
            errorMessage.contains('confirmed')) {
          safePrint('User is already confirmed, proceeding to sign in.');
          // エラーを無視して続行
        } else {
          // 3. 「コードが違う」など、その他のエラーの場合は、それをスローする
          throw e; 
        }
      }
      
      // 4. 確認が成功した(or スキップされた)ので、自動ログインを試みる
      await _signInUseCase(email, password);
       
      // 5. すべて成功
      state = state.copyWith(status: ConfirmationStatus.success);
      // --- ▲▲▲ 修正完了 ▲▲▲ ---

    } catch (e) {
      // 6. 確認コードエラー or ログインエラー
      state = state.copyWith(status: ConfirmationStatus.error, errorMessage: e.toString());
    }
  }
}
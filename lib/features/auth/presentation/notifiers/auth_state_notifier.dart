// ファイルパス: lib/features/auth/presentation/notifiers/auth_state_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  passwordResetRequired,
}

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? errorMessage;
  final String? flashMessage; // ★追加: フラッシュメッセージ

  const AuthState({
    this.status = AuthStatus.initial,
    this.username,
    this.errorMessage,
    this.flashMessage, // ★追加
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? errorMessage, 
    String? flashMessage, // ★追加: nullを渡してクリアできるようにする
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage, 
      flashMessage: flashMessage, // ★修正: 渡された値を使用
    );
  }
}

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AuthState(status: AuthStatus.initial)) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final attributes = await _authRepository.getCurrentUserAttributes();
      final username = attributes
          .firstWhere((element) =>
              element.userAttributeKey == AuthUserAttributeKey.preferredUsername)
          .value;
      state = state.copyWith(status: AuthStatus.authenticated, username: username);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUsername(String newUsername) {
    state = state.copyWith(username: newUsername);
  }

  // ログイン成功時にViewModelから呼び出す
  void setAuthenticated(String username, {String? message}) { 
      state = state.copyWith(
        status: AuthStatus.authenticated, 
        username: username,
        flashMessage: message,
      );
  }

    void clearFlashMessage() { 
      state = state.copyWith(flashMessage: null);
  }
  
  Future<void> resetPassword(String username) async {
    if (username.isEmpty) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: 'メールアドレスを入力してください');
      return;
    }
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.resetPassword(username: username);
      // 成功したら次の画面へ遷移させるステータスに変更
      state = state.copyWith(
          status: AuthStatus.passwordResetRequired, errorMessage: null);
    } on Exception catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> confirmPasswordReset(
      String username, String newPassword, String code) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: code,
      );
      // パスワードリセット成功後、ログイン画面に戻るために unauthenticated 状態に遷移させる
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on Exception catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString());
    }
  }
}
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
  final String? flashMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.username,
    this.errorMessage,
    this.flashMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? errorMessage, 
    String? flashMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage, 
      flashMessage: flashMessage,
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
      
      //preferredUsername が無い場合は email をフォールバックとして使用する防衛的実装
      final usernameAttribute = attributes.firstWhere(
        (element) => element.userAttributeKey == AuthUserAttributeKey.preferredUsername,
        orElse: () => attributes.firstWhere(
          (element) => element.userAttributeKey == AuthUserAttributeKey.email,
          orElse: () => const AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.preferredUsername, 
            value: 'Unknown User'
          ),
        ),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated, 
        username: usernameAttribute.value,
      );
    } catch (e) {
      safePrint('Session check failed: $e');
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
      state = state.copyWith(
          status: AuthStatus.passwordResetRequired, errorMessage: null);
    } on Exception catch (e) {
      // API層で投げられたエラーメッセージから "Exception: " の文字列を取り除いてUIへ渡す
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
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
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on Exception catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}
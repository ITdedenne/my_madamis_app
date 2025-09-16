// ファイルパス: lib/notifiers/auth_state_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// 認証状態を表現するenum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  confirmationRequired,
  error,
}

// 状態クラス
class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? usernameForConfirmation;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.usernameForConfirmation,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? usernameForConfirmation,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      usernameForConfirmation: usernameForConfirmation ?? this.usernameForConfirmation,
    );
  }
}

// StateNotifierProviderの定義
final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

// StateNotifier本体
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AuthState(status: AuthStatus.unauthenticated));

  Future<void> signUp(String username, String password, String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
 // RepositoryのsignUpメソッドを呼び出す
      final result = await _authRepository.signUp(
        username: username, // 画面のユーザー名
        password: password,
        email: email,       // 画面のメールアドレス
      );

      if (result.isSignUpComplete) {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: '登録が完了しました。ログインしてください。');
      } else {
        // 確認コード画面に渡すのはCognitoのログインIDである「メールアドレス」
        state = state.copyWith(status: AuthStatus.confirmationRequired, usernameForConfirmation: email);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: '登録に失敗しました: $e');
    }
  }

  Future<void> confirmSignUp(String username, String confirmationCode) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRepository.confirmSignUp(username: username, confirmationCode: confirmationCode);
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: '認証が完了しました。ログインしてください。');
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: '認証に失敗しました: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRepository.signIn(username: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'ログインに失敗しました: $e');
    }
  }
  
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
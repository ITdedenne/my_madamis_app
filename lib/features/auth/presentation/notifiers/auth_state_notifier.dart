// ファイルパス: lib/notifiers/auth_state_notifier.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

// 認証状態を表現するenum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  confirmationRequired,
  profileSetupRequired,
  passwordResetRequired, // 追加
  passwordResetSuccess,  // 追加
  error,
}

// 状態クラス
class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? usernameForConfirmation;
    final String? username;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.usernameForConfirmation,
    this.username,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? usernameForConfirmation,
    String? username,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage, // nullを許容してエラーメッセージをクリアできるようにする
      usernameForConfirmation:
          usernameForConfirmation ?? this.usernameForConfirmation,
          username: username ?? this.username,
    );
  }
}

// StateNotifierProviderの定義
final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

// StateNotifier本体
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository)
      : super(const AuthState(status: AuthStatus.unauthenticated));

  Future<void> signUp( String username,String password, String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await _authRepository.signUp(
          username: username,
        password: password,
        email: email,
      );
      if (result.isSignUpComplete) {
        state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: '登録が完了しました。ログインしてください。');
      } else {
        state = state.copyWith(
            status: AuthStatus.confirmationRequired,
            usernameForConfirmation: email);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: '登録に失敗しました: $e');
    }
  }

  // ▼▼▼ 3. confirmSignUpメソッドの成功時の処理を修正 ▼▼▼
  Future<void> confirmSignUp(String username, String confirmationCode) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.confirmSignUp(
          username: username, confirmationCode: confirmationCode);
      // 成功したら、unauthenticated ではなく profileSetupRequired に遷移
      state = state.copyWith(
          status: AuthStatus.profileSetupRequired,
          usernameForConfirmation: username // emailを保持しておく
          );
    } catch (e) {
      state =
          state.copyWith(status: AuthStatus.error, errorMessage: '認証に失敗しました: $e');
    }
  }

 Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.signIn(username: email, password: password);
      // --- 以下を追加 ---
      final attributes = await _authRepository.fetchUserAttributes();
      final username = attributes
          .firstWhere((element) =>
              element.userAttributeKey == AuthUserAttributeKey.preferredUsername)
          .value;
      state =
          state.copyWith(status: AuthStatus.authenticated, username: username);
      // --- ここまで追加 ---
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: 'ログインに失敗しました: $e');
    }
  }

  

  Future<bool> setupProfile({required String username, required String bio}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRepository.updateUserAttributes(username: username, bio: bio);
      // 成功したら authenticated 状態に遷移して完了
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: 'プロフィールの設定に失敗しました: $e');
      return false;
    }
  }

  // --- 以下を追加 ---
  Future<void> resetPassword(String username) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.resetPassword(username);
      state = state.copyWith(status: AuthStatus.passwordResetRequired);
    } on UserNotFoundException {
      state =
          state.copyWith(status: AuthStatus.error, errorMessage: '登録されていないメールアドレスです');
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: '予期せぬエラーが発生しました: $e');
    }
  }

  Future<void> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      state = state.copyWith(status: AuthStatus.passwordResetSuccess);
    } on AuthException catch (e) {
      String errorMessage;
      if (e is CodeMismatchException) {
        errorMessage = '認証コードが間違っています。';
      } else if (e is ExpiredCodeException) {
        errorMessage = '認証コードの有効期限が切れています。もう一度パスワードリセットを試してください。';
      } else if (e is InvalidPasswordException) {
        errorMessage = '新しいパスワードが要件を満たしていません。';
      } else {
        errorMessage = 'エラーが発生しました: ${e.message}';
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: errorMessage);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: '予期せぬエラーが発生しました: $e');
    }
  }
  // --- ここまで追加 ---

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // --- ▼▼▼ ここから追加 ▼▼▼ ---
  /// プロフィール更新時にユーザー名を同期するためのメソッド
  void updateUsername(String newUsername) {
    state = state.copyWith(username: newUsername);
  }
  // --- ▲▲▲ ここまで追加 ▲▲▲ ---
}
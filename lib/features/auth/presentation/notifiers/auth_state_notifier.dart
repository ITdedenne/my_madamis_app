// ファイルパス: lib/features/auth/presentation/notifiers/auth_state_notifier.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

enum AuthStatus {
 initial,
  loading,
  authenticated,
  unauthenticated,
  confirmationRequired,
  confirmationRequiredForUpdate, // メール更新時のコード確認状態
  profileSetupRequired,
  passwordResetRequired,
  passwordResetSuccess,
  emailUpdateSuccess, // メール更新成功状態
  passwordUpdateSuccess, // パスワード更新成功状態
  error,
}

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
    bool resetErrorMessage = false, // パラメータを追加
  }) {
    return AuthState(
      status: status ?? this.status,
      // resetErrorMessageがtrueならnullに、そうでなければ通常通り更新
      errorMessage: resetErrorMessage ? null : errorMessage ?? this.errorMessage,
      usernameForConfirmation:
          usernameForConfirmation ?? this.usernameForConfirmation,
      username: username ?? this.username,
    );
  }
}

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  //新しいメソッドを追加したときは"flutter pub run build_runner build --delete-conflicting-outputs"を入力。 
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository)
      : super(const AuthState(status: AuthStatus.unauthenticated));

  Future<void> createProfileAndSignUp({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await _authRepository.signUpWithProfile(
        email: email,
        password: password,
        username: username,
        bio: bio,
        twitterId: twitterId,
      );
      if (result.isSignUpComplete) {
        // 通常は発生しないが、Cognitoの設定によってはコード不要で登録完了する場合がある
        await signIn(email, password);
      } else {
        state = state.copyWith(
            status: AuthStatus.confirmationRequired,
            usernameForConfirmation: email);
      }
    } on UsernameExistsException {
      // ユーザーが既に存在し、未確認の場合
      try {
        await _authRepository.resendSignUpCode(username: email);
        state = state.copyWith(
          status: AuthStatus.confirmationRequired,
          usernameForConfirmation: email,
          errorMessage: 'このメールアドレスは登録済みです。確認コードを再送信しました。',
        );
      } catch (e) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: '確認コードの再送信に失敗しました。');
      }
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: '登録に失敗しました: ${e.message}');
    }
  }

  Future<void> confirmSignUp(
      String username, String confirmationCode, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.confirmSignUp(
          username: username, confirmationCode: confirmationCode);
      // 認証成功後、自動でサインイン
      await signIn(username, password);
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: '認証に失敗しました: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    // confirmSignUpから呼ばれる場合も考慮し、loading状態を一度だけ設定
    if (state.status != AuthStatus.loading) {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    }
    try {
      await _authRepository.signIn(username: email, password: password);
      final attributes = await _authRepository.fetchUserAttributes();
      final username = attributes
          .firstWhere((element) =>
              element.userAttributeKey ==
              AuthUserAttributeKey.preferredUsername)
          .value;
      state =
          state.copyWith(status: AuthStatus.authenticated, username: username);
    } on UserNotConfirmedException {
      // ユーザーが未確認の場合
      try {
        await _authRepository.resendSignUpCode(username: email);
        state = state.copyWith(
            status: AuthStatus.confirmationRequired,
            usernameForConfirmation: email,
            errorMessage: 'このアカウントは未確認です。確認コードをメールアドレスに送信しました。');
      } catch (e) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: '確認コードの再送信に失敗しました。');
      }
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: 'ログインに失敗しました: ${e.message}');
    }
  }

  Future<void> resetPassword(String username) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.resetPassword(username);
      state = state.copyWith(status: AuthStatus.passwordResetRequired);
    } on UserNotFoundException {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: '登録されていないメールアドレスです');
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

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

    Future<void> updateEmail(String newEmail) async {
    state = state.copyWith(status: AuthStatus.loading, resetErrorMessage: true);
    try {
      await _authRepository.updateEmail(newEmail);
      state = state.copyWith(
        status: AuthStatus.confirmationRequiredForUpdate,
        usernameForConfirmation: newEmail,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'メールアドレスの変更リクエストに失敗しました: ${e.message}',
      );
    }
  }

  Future<void> confirmUpdateEmail(String confirmationCode) async {
    state = state.copyWith(status: AuthStatus.loading, resetErrorMessage: true);
    try {
      await _authRepository.confirmUpdateEmail(confirmationCode);
      state = state.copyWith(status: AuthStatus.emailUpdateSuccess);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'メールアドレスの変更に失敗しました: ${e.message}',
      );
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, resetErrorMessage: true);
    try {
      await _authRepository.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(status: AuthStatus.passwordUpdateSuccess);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'パスワードの変更に失敗しました: ${e.message}',
      );
    }
  }

  /// 画面遷移後などに、一時的な状態をリセットする
  void resetStatus() {
    state = state.copyWith(
      status: AuthStatus.initial,
      resetErrorMessage: true,
    );
  }

  /// プロフィール更新時にユーザー名を同期するためのメソッド
  void updateUsername(String newUsername) {
    state = state.copyWith(username: newUsername);
  }
}
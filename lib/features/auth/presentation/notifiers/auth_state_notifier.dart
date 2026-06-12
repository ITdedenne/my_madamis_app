import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';

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
  return AuthStateNotifier(ref.watch(authRepositoryProvider), ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref; 

  AuthStateNotifier(this._authRepository, this._ref) : super(const AuthState(status: AuthStatus.initial)) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final attributes = await _authRepository.getCurrentUserAttributes();
      
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
    
    // 1. シナリオ手帳のデータ残留の原因となっていた大元のステータス情報を破棄
    _ref.invalidate(userScenarioStatusProvider);

    // 2. 各Repositoryがメモリに保持している可能性がある通信結果を破棄
    _ref.invalidate(profileRepositoryProvider);
    _ref.invalidate(scenarioRepositoryProvider);
    _ref.invalidate(friendsRepositoryProvider);
    _ref.invalidate(playerFinderRepositoryProvider);
    _ref.invalidate(groupSearchRepositoryProvider);

    // 3. (任意) その他、データを持ったままになるViewModelがあればここで破棄
    // _ref.invalidate(profileViewModelProvider);
    // _ref.invalidate(friendsViewModelProvider);
    // _ref.invalidate(myListPageStateProvider); // 絞り込みやソート状態もリセットしたい場合は追加

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
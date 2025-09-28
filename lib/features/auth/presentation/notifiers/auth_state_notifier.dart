// ファイルパス: lib/features/auth/presentation/notifiers/auth_state_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final String? username;

  const AuthState({
    this.status = AuthStatus.initial,
    this.username,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
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
      // ▼▼▼ ここのメソッド名を修正しました ▼▼▼
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
  void setAuthenticated(String username) {
      state = state.copyWith(status: AuthStatus.authenticated, username: username);
  }
}
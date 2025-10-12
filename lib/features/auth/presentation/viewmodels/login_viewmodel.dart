// ファイルパス: lib/features/auth/presentation/viewmodels/login_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final String? username;

  LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.username,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    String? username,
    bool resetError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetError ? null : errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
    );
  }
}

final loginViewModelProvider = StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginViewModel(authRepository);
});

class LoginViewModel extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository) : super(LoginState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, resetError: true);
    
    // ▼▼▼ 修正ポイント: サインイン処理前に、既存セッションを強制的にクリアする ▼▼▼
    try {
      // globalSignOut: true は AuthRepositoryImpl に実装済みだが、念のためここでもAmplifyのサインアウト処理を呼び出す
      await _authRepository.signOut(); 
    } catch (e) {
      safePrint('ログイン前のセッションクリアに失敗しましたが、サインインを続行します: $e');
    }
    // ▲▲▲ 修正ポイント終わり ▲▲▲
    
    try {
      await _authRepository.signIn(username: email, password: password);
      // ▼▼▼ ここのメソッド名を修正しました ▼▼▼
      final attributes = await _authRepository.getCurrentUserAttributes();
      // preferredUsernameの取得ロジックはSignInUseCaseに移管済みだが、ViewModel側も更新
      final username = attributes
          .firstWhere((element) =>
              element.userAttributeKey == AuthUserAttributeKey.preferredUsername,
              orElse: () => AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: email))
          .value;

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        username: username,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'ログインに失敗しました: ${e.message}',
      );
    } catch (e) {
        state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: '予期せぬエラーが発生しました: $e',
      );
    }
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/providers.dart';

// --- キャッシュリセットのための各Providerのインポート（ここでエラーを解消します） ---
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/user_search_viewmodel.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';

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
    bool resetUsername = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetError ? null : errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: resetUsername ? null : (username ?? this.username),
    );
  }
}

final loginViewModelProvider = StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginViewModel(authRepository, ref);
});

class LoginViewModel extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  LoginViewModel(this._authRepository, this._ref) : super(LoginState());

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'メールアドレスとパスワードを入力してください',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true, 
      resetError: true,
      isAuthenticated: false,
      resetUsername: true,
    );
    
    try {
      await _authRepository.signIn(username: email, password: password);
      
      final attributes = await _authRepository.getCurrentUserAttributes();
      final username = attributes
          .firstWhere((element) =>
              element.userAttributeKey == AuthUserAttributeKey.preferredUsername,
              orElse: () => AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: email))
          .value;

      // アプリ全体の認証状態（AuthStateNotifier）を新アカウントの情報に同期
      _ref.read(authStateNotifierProvider.notifier).setAuthenticated(username);

      // 【重要】Bアカウントでのログイン成功直後に、すべてのキャッシュを破棄する
      // 1. シナリオ手帳の大元のステータス情報
      _ref.invalidate(userScenarioStatusProvider);

      // 2. 各Repository
      _ref.invalidate(profileRepositoryProvider);
      _ref.invalidate(scenarioRepositoryProvider);
      _ref.invalidate(friendsRepositoryProvider);
      _ref.invalidate(playerFinderRepositoryProvider);
      _ref.invalidate(groupSearchRepositoryProvider);

      // 3. 各ViewModel・状態Provider（正しい変数名に修正済み）
      _ref.invalidate(profileViewModelProvider);
      _ref.invalidate(myListPageStateProvider);          // 修正済み
      _ref.invalidate(filteredAndSortedMyListProvider);  // 修正済み
      _ref.invalidate(searchScenariosViewModelProvider);
      _ref.invalidate(friendsViewModelProvider);
      _ref.invalidate(userSearchViewModelProvider);
      _ref.invalidate(playerFinderProvider);             // 修正済み
      _ref.invalidate(groupSearchViewModelProvider);

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
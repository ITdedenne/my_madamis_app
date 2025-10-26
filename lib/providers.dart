// ファイルパス: lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:my_madamis_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/data/repositories/scenario_repository_impl.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
// ★追加インポート
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart'; // UserScenarioStatusMapのために必要

// --- Repository Providers (既存) ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final scenarioRepositoryProvider = Provider<ScenarioRepository>((ref) {
  return ScenarioRepositoryImpl();
});

// --- Scenario Logbook Providers (UseCase, Notifier) ---

// ★修正: Notifier Providerを先に定義 (他のProviderで参照するため)
// ★エラーに出ていた名前 userScenarioStatusProvider に統一
final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, Map<String, UserScenarioStatus>>((ref) {
  // NotifierはGetMyListUseCaseのみに依存
  return UserScenarioStatusNotifier(ref.watch(getMyListUseCaseProvider));
});

// ★修正: GetMyListUseCaseProviderを定義 (エラー解消)
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));

// ★修正: UpdateUserScenarioStatusUseCaseProviderを定義 (エラー解消)
// DB更新後、Notifierの状態を更新するために、Notifierのインスタンスを渡す
final updateUserScenarioStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(scenarioRepositoryProvider);
  // NotifierProviderのNotifierインスタンス自体を取得
  final notifier = ref.read(userScenarioStatusProvider.notifier); 
  return UpdateUserScenarioStatusUseCase(repository, notifier);
});
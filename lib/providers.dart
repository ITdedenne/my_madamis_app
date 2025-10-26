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
// ★Scenario Logbookの依存関係
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart'; 

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

// --- Scenario Logbook Providers ---

// 1. GetMyListUseCase (DBからUserScenarioリストを取得するビジネスロジック)
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));

// 2. ★追加: DBからマイリストデータを非同期で取得するFutureProvider
// MyListのデータソースとして使用し、DB更新後に invalidate されることで再取得される
final myListFutureProvider = FutureProvider<List<UserScenario>>((ref) {
  return ref.watch(getMyListUseCaseProvider).call();
});

// 3. initialStatusMapProvider (DBからロードした初期状態マップ - Notifier初期化用)
final initialStatusMapProvider = FutureProvider<Map<String, UserScenarioStatus>>((ref) async {
  // myListFutureProviderのデータがロードされるのを待つ
  final myList = await ref.watch(myListFutureProvider.future); 
  return {for (var item in myList) item.scenario.id: item.status};
});

// 4. UserScenarioStatusNotifier (グローバルな状態を保持し、即時更新)
// このProviderを watch しているUIは、updateStatusが呼ばれると即座に再構築される。
final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, Map<String, UserScenarioStatus>>((ref) {
  // initialStatusMapProvider のデータがロードされるまで待つ
  final initialStatuses = ref.watch(initialStatusMapProvider).value ?? {};

  return UserScenarioStatusNotifier(initialStatuses);
});

// 5. UpdateUserScenarioStatusUseCase (DB更新と同時にNotiferも更新)
final updateUserScenarioStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(scenarioRepositoryProvider);
  final notifier = ref.read(userScenarioStatusProvider.notifier); 
  return UpdateUserScenarioStatusUseCase(repository, notifier);
});

// 6. マイリストの全UserScenarioリスト（リアクティブなデータソース）
// 探す画面のアイコンの状態（userScenarioStatusProvider）が変更されたら、
// このProviderを watch している MyListViewModel のロジックが再実行され、UIが更新される。
final reactiveUserScenariosProvider = Provider<AsyncValue<List<UserScenario>>>((ref) {
    // Notifierの状態（Map）を監視
    ref.watch(userScenarioStatusProvider);
    
    // DBの最新データ（myListFutureProvider）のAsyncValueを直接返す。
    return ref.watch(myListFutureProvider);
});
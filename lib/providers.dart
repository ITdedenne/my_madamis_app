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
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; // MyListViewModelの依存関係

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

// 1. GetMyListUseCase (DBからUserScenarioリストを取得)
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));

// 2. 初期状態をロードするFutureProvider (DBからロード。リフレッシュ時はこれをinvalidateする)
final initialStatusMapProvider = FutureProvider<Map<String, UserScenarioStatus>>((ref) async {
  final myList = await ref.watch(getMyListUseCaseProvider).call();
  return {for (var item in myList) item.scenario.id: item.status};
});

// 3. UserScenarioStatusNotifier (グローバルな状態を保持し、即時更新)
final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, Map<String, UserScenarioStatus>>((ref) {
  // DBからの初期値（AsyncValue）を監視し、値を取得
  final initialStatusesAsync = ref.watch(initialStatusMapProvider);
  final initialStatuses = initialStatusesAsync.value ?? {};

  // Notifierを初期化
  return UserScenarioStatusNotifier(initialStatuses);
});

// 4. UpdateUserScenarioStatusUseCase (DB更新と同時にNotiferも更新)
final updateUserScenarioStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(scenarioRepositoryProvider);
  // Notifierのインスタンスをreadして渡し、内部でupdateStatusを呼び出せるようにする
  final notifier = ref.read(userScenarioStatusProvider.notifier); 
  return UpdateUserScenarioStatusUseCase(repository, notifier);
});

// 5. マイリストの全UserScenarioリスト（リアクティブなデータソース）
// Status Mapの変更（UIの即時更新）と、DBからの完全なデータ（マイリスト）を結合する。
final reactiveUserScenariosProvider = Provider<AsyncValue<List<UserScenario>>>((ref) {
    // Notifierの状態（Map）を監視。これが変更されるとこのProviderが再実行される
    ref.watch(userScenarioStatusProvider);
    
    // DBから最新のUserScenarioリストを取得するFutureProviderを監視
    // DB書き込み後、UserScenarioStatusNotifierが更新されることで、このProviderが再実行され、
    // DBから最新のMyListデータを再取得し、UIが更新される。
    final myListAsync = ref.watch(getMyListUseCaseProvider);

    return myListAsync.when(
        data: (list) => AsyncValue.data(list),
        loading: () => const AsyncValue.loading(),
        error: (err, st) => AsyncValue.error(err, st),
    );
});
// MyListViewModelは filteredAndSortedMyListProvider を持つため、そのロジックはmy_list_viewmodel.dart内で
// reactiveUserScenariosProvider を使って再定義されることを期待
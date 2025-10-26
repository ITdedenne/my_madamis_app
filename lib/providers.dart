// ファイルパス: lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_madamis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_madamis_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:my_madamis_app/features/profile/domain/repositories/profile_repository.dart';
// ... (他のインポートはそのまま)
import 'package:my_madamis_app/features/scenario_logbook/data/repositories/scenario_repository_impl.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
// ★Scenario Logbookの依存関係
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart'; 
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:my_madamis_app/features/settings/domain/repositories/settings_repository.dart'; 
// ★MyListViewModelの依存関係は不要なため削除（Unused import）
// import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; 

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

// 1. GetMyListUseCase (同期的なロジックのみを保持するUseCase)
final getMyListUseCaseSynchronousProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));

// 2. ★修正: DBからマイリストデータ（UserScenarioのリスト）を非同期で取得する FutureProvider
// UIやViewModelはこれを監視し、DB更新後にinvalidateされるデータソースとなる。
final myListFutureProvider = FutureProvider<List<UserScenario>>((ref) {
  return ref.watch(getMyListUseCaseSynchronousProvider).call();
});

// 3. initialStatusMapProvider (初期状態マップ - Notifier初期化用)
final initialStatusMapProvider = FutureProvider<Map<String, UserScenarioStatus>>((ref) async {
  // myListFutureProviderのデータがロードされるのを待ち、Mapに変換
  final myList = await ref.watch(myListFutureProvider.future);
  return {for (var item in myList) item.scenario.id: item.status};
});

// 4. UserScenarioStatusNotifier (グローバルな状態を保持し、即時更新)
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

// 6. ★削除: 不要な reactiveUserScenariosProvider を削除

// 7. MyListViewModelが直接参照する全シナリオのProvider (既存のViewModelへの互換性維持のため)
final allScenariosProvider = Provider<AsyncValue<List<UserScenario>>>((ref) {
  // myListFutureProviderのAsyncValueをそのまま返す
  return ref.watch(myListFutureProvider);
});
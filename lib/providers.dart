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

// --- 【追加】Scenario Logbook の Usecase を import ---
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart';
// ↓↓↓↓ 不足していた import を追加 ↓↓↓↓
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
// --- 【追加】ここまで ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

// --- Scenario Logbook ---

final scenarioRepositoryProvider = Provider<ScenarioRepository>((ref) {
  return ScenarioRepositoryImpl();
});

// --- 【追加】Scenario Logbook Usecases ---

/// [探す] 画面用の Usecase
final getScenariosUsecaseProvider = Provider<GetScenariosUsecase>((ref) {
  final repository = ref.read(scenarioRepositoryProvider);
  return GetScenariosUsecase(repository);
});

/// [マイリスト] 画面用の Usecase
final getMyListUsecaseProvider = Provider<GetMyListUsecase>((ref) {
  final repository = ref.read(scenarioRepositoryProvider);
  return GetMyListUsecase(repository);
});

/// ステータス更新用の Usecase
final updateUserScenarioStatusUsecaseProvider =
    Provider<UpdateUserScenarioStatusUsecase>((ref) {
  final repository = ref.read(scenarioRepositoryProvider);
  return UpdateUserScenarioStatusUsecase(repository);
});
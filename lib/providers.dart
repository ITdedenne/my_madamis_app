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
// ★ 追加
import 'package:my_madamis_app/features/friends/data/repositories/friends_repository_impl.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';

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

// ★ 追加: フレンズ機能のリポジトリ
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepositoryImpl();
});
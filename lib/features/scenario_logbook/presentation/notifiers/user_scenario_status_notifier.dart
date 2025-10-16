// ファイルパス: lib/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/providers.dart';

// UseCaseのProvider
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));
final updateUserScenarioStatusUseCaseProvider = Provider((ref) => UpdateUserScenarioStatusUseCase(ref.watch(scenarioRepositoryProvider)));

// 状態管理用のNotifier
final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, Map<String, UserScenarioStatus>>((ref) {
  return UserScenarioStatusNotifier(ref);
});

class UserScenarioStatusNotifier extends StateNotifier<Map<String, UserScenarioStatus>> {
  final Ref _ref;

  UserScenarioStatusNotifier(this._ref) : super({}) {
    _loadInitialStatuses();
  }

  // 初期データをRepositoryから読み込む
  Future<void> _loadInitialStatuses() async {
    final myList = await _ref.read(getMyListUseCaseProvider)();
    final initialMap = {for (var item in myList) item.scenario.id: item.status};
    if (mounted) {
      state = initialMap;
    }
  }

  // ステータスを更新する唯一の窓口
  Future<void> updateStatus(String scenarioId, UserScenarioStatus newStatus) async {
    try {
      //先にRepository (DB) を更新
      await _ref.read(updateUserScenarioStatusUseCaseProvider)(scenarioId, newStatus);

      // DB更新が成功したら、UI（state）を更新
      final newState = Map<String, UserScenarioStatus>.from(state);
      if (newStatus.isUnregistered) {
        newState.remove(scenarioId);
      } else {
        newState[scenarioId] = newStatus;
      }
      if (mounted) {
        state = newState;
      }
    } catch (e) {
      // TODO: エラーハンドリング (SnackBar表示など)
      print('Failed to update status: $e');
    }
  }
  
  // データを再読み込みするためのメソッド
  Future<void> refresh() async {
    await _loadInitialStatuses();
  }
}
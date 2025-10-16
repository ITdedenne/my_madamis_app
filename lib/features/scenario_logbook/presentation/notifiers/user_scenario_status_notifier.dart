// ファイルパス: lib/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
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
    state = initialMap;
  }

  // ステータスを更新する唯一の窓口
  Future<void> updateStatus(String scenarioId, UserScenarioStatus newStatus) async {
    final originalState = state;
    
    // UIを即時反映
    final newState = Map<String, UserScenarioStatus>.from(state);
    if (newStatus.isUnregistered) {
      newState.remove(scenarioId);
    } else {
      newState[scenarioId] = newStatus;
    }
    state = newState;

    try {
      // Repository (DB) を更新
      await _ref.read(updateUserScenarioStatusUseCaseProvider)(scenarioId, newStatus);
      // マイリスト画面の表示用データをリフレッシュして同期
      final _ = _ref.refresh(filteredAndSortedMyListProvider);
    } catch (e) {
      // 失敗したらUIを元に戻す
      state = originalState;
      // TODO: エラーハンドリング (SnackBar表示など)
    }
    
  }
}
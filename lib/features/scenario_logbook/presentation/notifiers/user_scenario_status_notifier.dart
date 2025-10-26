// ファイルパス: lib/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // safePrint用

// UseCaseのProvider (変更なし)
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));
final updateUserScenarioStatusUseCaseProvider = Provider((ref) => UpdateUserScenarioStatusUseCase(ref.watch(scenarioRepositoryProvider)));

// 状態管理用のNotifier
final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, AsyncValue<Map<String, UserScenarioStatus>>>((ref) {
  return UserScenarioStatusNotifier(ref);
});

// ★ 状態を AsyncValue でラップしてロード中/エラー状態を表現
class UserScenarioStatusNotifier extends StateNotifier<AsyncValue<Map<String, UserScenarioStatus>>> {
  final Ref _ref;

  UserScenarioStatusNotifier(this._ref) : super(const AsyncValue.loading()) { // 初期状態をロード中に設定
    _loadInitialStatuses();
  }

  // 初期データをRepositoryから読み込む
  Future<void> _loadInitialStatuses() async {
    // 既にロード中でなければロード中に設定
    if (state is! AsyncLoading) {
       state = const AsyncValue.loading();
    }
    try {
      final myList = await _ref.read(getMyListUseCaseProvider)();
      final initialMap = {for (var item in myList) item.scenario.id: item.status};
      // データ取得成功
      if (mounted) {
         state = AsyncValue.data(initialMap);
         safePrint("UserScenario statuses loaded successfully: ${initialMap.length} items.");
      }
    } catch (e, stackTrace) {
      // データ取得失敗
      safePrint("Error loading initial UserScenario statuses: $e");
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  // ステータスを更新する唯一の窓口
  Future<void> updateStatus(String scenarioId, UserScenarioStatus newStatus) async {
    // 現在の状態がデータを持っている場合のみ更新処理を行う
    state.whenData((currentStatuses) async {
        // UI上は即時反映を試みる（オプティミスティックUI）
        final optimisticState = Map<String, UserScenarioStatus>.from(currentStatuses);
         if (newStatus.isUnregistered) {
            optimisticState.remove(scenarioId);
          } else {
            optimisticState[scenarioId] = newStatus;
          }
         if (mounted) {
           state = AsyncValue.data(optimisticState); // 仮の状態を先に反映
         }

        try {
          // Repository (DB) を非同期で更新
          await _ref.read(updateUserScenarioStatusUseCaseProvider)(scenarioId, newStatus);
          // DB更新が成功したら、状態は optimisticState のままでOK
          safePrint("Successfully updated status for scenario $scenarioId in DB.");

        } catch (e, stackTrace) {
          // DB更新が失敗した場合
          safePrint('Failed to update status in DB for scenario $scenarioId: $e');
          // UIの状態を元の状態（DB更新前）に戻す
           if (mounted) {
             state = AsyncValue.data(currentStatuses);
             // エラーをユーザーに通知する方法を検討 (例: SnackBar)
             // ここでは state をエラー状態にはしないが、別途エラー通知用の StateProvider などを用意しても良い
           }
        }
    });
     // stateが loading や error の場合は何もしない（or エラー表示）
  }

  // データを再読み込みするためのメソッド
  Future<void> refresh() async {
    safePrint("Refreshing UserScenario statuses...");
    await _loadInitialStatuses();
  }
}
// ファイルパス: lib/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // safePrintのために必要
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

// Map<ScenarioId, UserScenarioStatus>
typedef UserScenarioStatusMap = Map<String, UserScenarioStatus>;

class UserScenarioStatusNotifier extends StateNotifier<UserScenarioStatusMap> {
  // ★修正: 初期値のみを受け取る
  UserScenarioStatusNotifier(UserScenarioStatusMap initialStatuses) : super(initialStatuses);

  // ステータスを更新する（UseCaseから呼ばれ、状態更新のみを行う）
  void updateStatus(String scenarioId, UserScenarioStatus newStatus) {
    // 状態が変更されていない場合は何もしない
    if (state[scenarioId] == newStatus && !newStatus.isUnregistered) {
      return; 
    }
    
    // 新しいMapインスタンスを作成して変更を加える
    final newState = Map<String, UserScenarioStatus>.from(state);

    if (newStatus.isUnregistered) {
      newState.remove(scenarioId);
      safePrint('Status removed in Notifier for $scenarioId');
    } else {
      newState[scenarioId] = newStatus;
      safePrint('Status updated in Notifier for $scenarioId to $newStatus');
    }

    // Riverpodに状態の変更を通知 (新しいインスタンスを割り当てる)
    if (mounted) {
      state = newState; 
    }
  }
}
// Provider定義は lib/providers.dart に移動したため、このファイルから削除
// ファイルパス: lib/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // safePrintのために必要
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
// ★修正: providers.dartから必要なProviderをインポート
import 'package:my_madamis_app/providers.dart'; 

// Map<ScenarioId, UserScenarioStatus>
typedef UserScenarioStatusMap = Map<String, UserScenarioStatus>;

class UserScenarioStatusNotifier extends StateNotifier<UserScenarioStatusMap> {
  final GetMyListUseCase _getMyListUseCase;

  // ★修正: RefではなくUseCaseを直接受け取る
  UserScenarioStatusNotifier(this._getMyListUseCase) : super({}) {
    _loadInitialStatuses();
  }

  // 初期データをRepositoryから読み込む
  Future<void> _loadInitialStatuses() async {
    try {
      // ★修正: UseCaseを直接呼び出す
      final myList = await _getMyListUseCase();
      final initialMap = {for (var item in myList) item.scenario.id: item.status};
      if (mounted) {
        state = initialMap;
      }
    } catch (e) {
      safePrint('Error loading initial statuses: $e');
    }
  }

  // ステータスを更新する（UseCaseから呼ばれ、状態更新のみを行う）
  void updateStatus(String scenarioId, UserScenarioStatus newStatus) {
    final newState = Map<String, UserScenarioStatus>.from(state);

    if (newStatus.isUnregistered) {
      // 未登録の場合はMapから削除
      newState.remove(scenarioId);
      safePrint('Status removed in Notifier for $scenarioId');
    } else {
      // 新しい状態を上書き
      newState[scenarioId] = newStatus;
      safePrint('Status updated in Notifier for $scenarioId to $newStatus');
    }

    if (mounted) {
      state = newState; // これがUI更新をトリガーする
    }
  }
  
  // データを再読み込みするためのメソッド（マイリストのRefreshIndicatorから呼ばれる）
  Future<void> refresh() async {
    await _loadInitialStatuses();
  }
}

// ★削除: Provider定義は providers.dart に移動したため、ここでは不要
/*
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));
final updateUserScenarioStatusUseCaseProvider = Provider((ref) => UpdateUserScenarioStatusUseCase(ref.watch(scenarioRepositoryProvider)));

final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, Map<String, UserScenarioStatus>>((ref) {
  return UserScenarioStatusNotifier(ref);
});
*/
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
// state: Map<ScenarioId, UserScenarioStatus>
final userScenarioStatusProvider = StateNotifierProvider<UserScenarioStatusNotifier, Map<String, UserScenarioStatus>>((ref) {
  return UserScenarioStatusNotifier(ref);
});

class UserScenarioStatusNotifier extends StateNotifier<Map<String, UserScenarioStatus>> {
  final Ref _ref;

  UserScenarioStatusNotifier(this._ref) : super({}) {
    // コンストラクタで初期データをロード
    _loadInitialStatuses();
  }

  // 初期データをRepositoryから読み込む
  Future<void> _loadInitialStatuses() async {
    try {
      // RepositoryImplのfetchMyList()はログイン中のユーザーIDでフィルタリングしている
      final myList = await _ref.read(getMyListUseCaseProvider)(); 
      final initialMap = {for (var item in myList) item.scenario.id: item.status};
      if (mounted) {
        state = initialMap; // 状態を新しいデータで置き換え
      }
    } catch (e) {
      // 認証エラーなどでデータが取得できない場合は空のマップにする
      print('Failed to load initial statuses (MyList): $e');
      if (mounted) {
        state = {};
      }
    }
  }

  // ステータスを更新する唯一の窓口
  Future<void> updateStatus(String scenarioId, UserScenarioStatus newStatus) async {
    try {
      // 1. Repository (DB) を更新/削除
      await _ref.read(updateUserScenarioStatusUseCaseProvider)(scenarioId, newStatus);

      // 2. DB更新が成功したら、UI（state）を更新
      final newState = Map<String, UserScenarioStatus>.from(state);
      
      if (newStatus.isUnregistered) {
        // 未登録に戻す場合、マップから削除
        newState.remove(scenarioId);
      } else {
        // 所持/通過済/両方に更新する場合、マップに追加/更新
        newState[scenarioId] = newStatus;
      }
      
      if (mounted) {
        state = newState; // ★★★ これにより、このProviderを監視しているUI（MyListPage）が自動更新されます ★★★
      }
    } catch (e) {
      // TODO: エラーハンドリング (SnackBar表示など)
      print('Failed to update status: $e');
      // 念のため、エラーが発生した場合は最新のDB状態を再読み込みするのも手
      refresh();
    }
  }
  
  // データを再読み込みするためのメソッド（Pull-to-Refresh用）
  Future<void> refresh() async {
    // DBから最新データを再取得
    await _loadInitialStatuses();
  }
}
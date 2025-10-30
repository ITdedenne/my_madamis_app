// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/providers.dart';

// ★追加: ScenarioPageをインポート
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario_page.dart';


// --- 状態とフィルターの定義 ---

enum MyListFilter { all, played, possessed } // 0:すべて, 1:通過済, 2:所持
enum SortOrder { byTitle, byAuthor }

class MyListPageState {
  final MyListFilter filter;
  final SortOrder sortOrder;

  MyListPageState({
    this.filter = MyListFilter.all,
    this.sortOrder = SortOrder.byTitle,
  });

  MyListPageState copyWith({MyListFilter? filter, SortOrder? sortOrder}) {
    return MyListPageState(
      filter: filter ?? this.filter,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

// UIの状態（フィルター、ソート順）を管理する
final myListPageStateProvider = StateProvider<MyListPageState>((ref) {
  return MyListPageState();
});

// ★★★ allScenariosProvider を修正 ★★★
// 全シナリオデータを保持するProvider（Scenarioマスターデータ）
final allScenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  try {
    final repo = ref.watch(scenarioRepositoryProvider);
    
    // 1. 'page: 1' を 'nextToken: null' に修正
    // 2. 戻り値が ScenarioPage になったため、await して .scenarios を返す
    final ScenarioPage scenarioPage = await repo.fetchScenarios(nextToken: null, limit: 200); 
    return scenarioPage.scenarios;

  } catch (e) {
    debugPrint('Error loading all scenarios: $e');
    // エラー時はrethrowする
    rethrow;
  }
});

// --- メインのデータ処理 Provider (フィルタリングとソートを実行) ---

final filteredAndSortedMyListProvider = Provider<Map<String, List<UserScenario>>>((ref) {
  // allScenariosAsyncの状態を監視し、データがロードされるのを待つ
  final allScenariosAsync = ref.watch(allScenariosProvider);
  // userStatusesの状態を監視し、変更があれば再計算する
  final userStatuses = ref.watch(userScenarioStatusProvider);
  final pageState = ref.watch(myListPageStateProvider);

  // 全シナリオデータがロードされるまで待つ
  return allScenariosAsync.when(
    data: (allScenarios) {
      // ユーザーのステータスとシナリオ本体を結合したリストを作成
      // userStatusesには、ログインユーザーが「所持済」または「通過済」にしたシナリオのみが含まれていることを前提とする
      final myList = userStatuses.entries.map((entry) {
        final scenario = allScenarios.firstWhereOrNull((s) => s.id == entry.key);
        // シナリオマスターが存在しない場合はスキップ
        if (scenario == null) return null;
        return UserScenario(scenario: scenario, status: entry.value);
      }).whereType<UserScenario>().toList(); // ここで得られるのは「登録済み」シナリオのみ

      List<UserScenario> filtered;
      
      // ★★★ フィルタリングロジック（修正済み/再確認） ★★★
      switch (pageState.filter) {
        case MyListFilter.played:
          // 通過済: isPlayed が true
          filtered = myList.where((s) => s.status.isPlayed).toList();
          break;
        case MyListFilter.possessed:
          // 所持: isPossessed が true
          filtered = myList.where((s) => s.status.isPossessed).toList();
          break;
        case MyListFilter.all:
          // すべて: isPlayed OR isPossessed が true
          // myList自体が既に isPlayed OR isPossessed が true のものしか含まれないため、
          // フィルタリングは不要だが、コードの意図を明確にするため、!isUnregisteredを残す
          filtered = myList.where((s) => !s.status.isUnregistered).toList();
          break;
      }
      
      // ソートロジック
      filtered.sort((a, b) {
        switch (pageState.sortOrder) {
          case SortOrder.byTitle:
            return a.scenario.title.compareTo(b.scenario.title);
          case SortOrder.byAuthor:
            return a.scenario.authorName.compareTo(b.scenario.authorName);
        }
      });

      // グループ化ロジック (頭文字などでグループ化)
      return groupBy(filtered, (UserScenario s) {
        final key = (pageState.sortOrder == SortOrder.byTitle)
            ? s.scenario.title.isNotEmpty ? s.scenario.title.substring(0, 1) : '#'
            : s.scenario.authorName.isNotEmpty ? s.scenario.authorName.substring(0, 1) : '#';
        return key.toUpperCase();
      });
    },
    // ロード中、エラー時は空のマップを返す
    loading: () => {},
    error: (err, stack) {
      debugPrint('Error in filteredAndSortedMyListProvider: $err');
      return {};
    },
  );
});
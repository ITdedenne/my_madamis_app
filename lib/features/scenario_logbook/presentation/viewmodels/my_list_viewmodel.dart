// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/providers.dart';

enum MyListFilter { all, played, possessed }
enum SortOrder { byTitle, byAuthor }

// このViewModelはUIの状態（フィルターやソート順）のみを管理する
final myListPageStateProvider = StateProvider<MyListPageState>((ref) {
  return MyListPageState();
});

// 表示用のデータを生成するProvider
final filteredAndSortedMyListProvider = Provider<Map<String, List<UserScenario>>>((ref) {
  final allScenariosAsync = ref.watch(allScenariosProvider);
  final userStatuses = ref.watch(userScenarioStatusProvider);
  final pageState = ref.watch(myListPageStateProvider);

  // 全シナリオデータがロードされるまで待つ
  return allScenariosAsync.when(
    data: (allScenarios) {
      final myList = userStatuses.entries.map((entry) {
        final scenario = allScenarios.firstWhereOrNull((s) => s.id == entry.key);
        if (scenario == null) return null;
        return UserScenario(scenario: scenario, status: entry.value);
      }).whereType<UserScenario>().toList();

      List<UserScenario> filtered;
      switch (pageState.filter) {
        case MyListFilter.played:
          filtered = myList.where((s) => s.status.isPlayed).toList();
          break;
        case MyListFilter.possessed:
          filtered = myList.where((s) => s.status.isPossessed).toList();
          break;
        case MyListFilter.all:
          filtered = myList;
          break;
      }
      
      filtered.sort((a, b) {
        switch (pageState.sortOrder) {
          case SortOrder.byTitle:
            return a.scenario.title.compareTo(b.scenario.title);
          case SortOrder.byAuthor:
            return a.scenario.authorName.compareTo(b.scenario.authorName);
        }
      });

      return groupBy(filtered, (UserScenario s) {
        final key = (pageState.sortOrder == SortOrder.byTitle)
            ? s.scenario.title.substring(0, 1)
            : s.scenario.authorName.substring(0, 1);
        return key.toUpperCase();
      });
    },
    loading: () => {}, // ロード中は空のマップ
    error: (err, stack) => {}, // エラー時も空のマップ
  );
});


// 全シナリオデータを保持するProvider（Repositoryから一度だけ取得）
final allScenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  // ページングなしで全件取得
  return repo.fetchScenarios(page: 1, limit: 200);
});

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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull用
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/providers.dart';

enum MyListFilter { all, played, possessed, wantsToGm }
enum SortOrder { byTitle, byAuthor, newest } // "newest" (登録順) もあると便利かもですが一旦既存維持

// UI状態
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

final myListPageStateProvider = StateProvider<MyListPageState>((ref) {
  return MyListPageState();
});

// S3から全シナリオを取得するProvider
final allScenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  // 全件取得 (ページネーションなし、あるいは十分大きなリミットで取得)
  // ※実運用ではキャッシュ戦略が重要ですが、現状のアーキテクチャに従います
  return repo.fetchScenarios(page: 1, limit: 4000); 
});

// ★ 修正: Mapではなく List<UserScenario> を返すように変更
final filteredAndSortedMyListProvider = Provider<AsyncValue<List<UserScenario>>>((ref) {
  final allScenariosAsync = ref.watch(allScenariosProvider);
  final userStatuses = ref.watch(userScenarioStatusProvider);
  final pageState = ref.watch(myListPageStateProvider);

  return allScenariosAsync.whenData((allScenarios) {
    // 1. ステータスがあるものだけを結合
    final myList = userStatuses.entries.map((entry) {
      final scenario = allScenarios.firstWhereOrNull((s) => s.id == entry.key);
      if (scenario == null) return null;
      return UserScenario(scenario: scenario, status: entry.value);
    }).whereType<UserScenario>().toList();

    // 2. フィルタリング
    List<UserScenario> filtered;
    switch (pageState.filter) {
      case MyListFilter.played:
        filtered = myList.where((s) => s.status.isPlayed).toList();
        break;
      case MyListFilter.possessed:
        filtered = myList.where((s) => s.status.isPossessed).toList();
        break;
      case MyListFilter.wantsToGm:
        filtered = myList.where((s) => s.status.wantsToGm).toList();
        break;
      case MyListFilter.all:
      default:
        filtered = myList;
        break;
    }

    // 3. ソート
    filtered.sort((a, b) {
      switch (pageState.sortOrder) {
        case SortOrder.byTitle:
          return a.scenario.title.compareTo(b.scenario.title);
        case SortOrder.byAuthor:
          return a.scenario.authorName.compareTo(b.scenario.authorName);
        default:
          return 0;
      }
    });

    // ★ グループ化せず、フラットなリストを返す
    return filtered;
  });
});
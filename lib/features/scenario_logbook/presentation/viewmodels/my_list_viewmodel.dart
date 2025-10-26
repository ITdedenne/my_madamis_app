// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/providers.dart';

enum MyListFilter { all, played, possessed }
enum SortOrder { byTitle, byAuthor }

// UIの状態（フィルターやソート順）のみを管理
final myListPageStateProvider = StateProvider<MyListPageState>((ref) {
  return MyListPageState();
});

// 表示用のデータを生成するProvider
final filteredAndSortedMyListProvider = Provider<Map<String, List<UserScenario>>>((ref) {
  // ★★★ 修正: AsyncValue<List<Scenario>> を watch する ★★★
  final allScenariosAsync = ref.watch(allScenariosProvider);
  // ★★★ 修正: AsyncValue<Map<String, UserScenarioStatus>> を watch する ★★★
  final userStatusesAsync = ref.watch(userScenarioStatusProvider);
  final pageState = ref.watch(myListPageStateProvider);

  // 両方の AsyncValue が data 状態の場合のみ処理を実行
  return allScenariosAsync.when(
    data: (allScenarios) {
      return userStatusesAsync.when(
        data: (userStatuses) {
          // --- データが揃った場合の処理 ---
          final myList = userStatuses.entries.map((entry) { // ★★★ userStatuses (Map) の .entries にアクセス ★★★
            final scenario = allScenarios.firstWhereOrNull((s) => s.id == entry.key);
            // シナリオ情報が見つからないデータは除外
            if (scenario == null) return null;
            return UserScenario(scenario: scenario, status: entry.value);
          }).whereType<UserScenario>().toList(); // nullを除去

          // フィルタリング
          List<UserScenario> filtered;
          switch (pageState.filter) {
            case MyListFilter.played:
              filtered = myList.where((s) => s.status.isPlayed).toList();
              break;
            case MyListFilter.possessed:
              filtered = myList.where((s) => s.status.isPossessed).toList();
              break;
            case MyListFilter.all:
            default: // フォールバック
              filtered = myList;
              break;
          }

          // ソート
          filtered.sort((a, b) {
            switch (pageState.sortOrder) {
              case SortOrder.byAuthor:
                // 日本語も考慮したソート
                return compareNatural(a.scenario.authorName, b.scenario.authorName);
              case SortOrder.byTitle:
              default: // フォールバック
                 // 日本語も考慮したソート
                return compareNatural(a.scenario.title, b.scenario.title);
            }
          });

          // グルーピング
          return groupBy(filtered, (UserScenario s) {
             final keyString = (pageState.sortOrder == SortOrder.byAuthor)
                ? s.scenario.authorName
                : s.scenario.title;
             // 最初の文字を取得（空文字列対策）
             final firstChar = keyString.isNotEmpty ? keyString.substring(0, 1) : '#';
             // TODO: 必要であればひらがな/カタカナ/漢字/英数字などで分類するロジックを追加
             return firstChar.toUpperCase(); // 簡単のため頭文字でグループ化
          });
          // --- データが揃った場合の処理ここまで ---
        },
        // userStatuses が loading または error の場合
        loading: () => {}, // 空のマップを返す
        error: (err, stack) {
          print("Error loading user statuses for MyList: $err"); // エラーログ
          return {}; // 空のマップを返す
        },
      );
    },
    // allScenarios が loading または error の場合
    loading: () => {}, // 空のマップを返す
    error: (err, stack) {
       print("Error loading all scenarios for MyList: $err"); // エラーログ
      return {}; // 空のマップを返す
    },
  );
});


// 全シナリオデータを保持するProvider（Repositoryから取得）
// ★★★ 修正: ページングせずに全件取得を試みる (件数が多い場合は要見直し) ★★★
final allScenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  // limit を大きくして1回で取得しようと試みる。
  // 注意: データ量が多い場合、DynamoDBの制限やパフォーマンスに影響する可能性あり。
  // 本番環境ではページネーションするか、必要なデータのみ取得する方式を検討。
  return repo.fetchScenarios(page: 1, limit: 1000); // 仮に1000件まで
});


// MyListPageの状態クラス (変更なし)
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
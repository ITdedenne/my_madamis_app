// lib/features/scenario_logbook/presentation/pages/my_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/logbook_list_item.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // フィルタ・ソート済みのリストを監視
    final List<ScenarioLogbookEntry> scenarios =
        ref.watch(filteredMyListProvider);
    // ViewModelの状態（ロード状態など）を監視
    final MyListViewState state = ref.watch(myListViewModelProvider);
    
    final MyListFilter currentFilter = ref.watch(myListFilterProvider);
    // --- ▼ 追加 ▼ ---
    // 現在のソート順 (要件 1.2.7)
    final MyListSortOrder currentSort = ref.watch(myListSortProvider);
    // --- ▲ 追加 ▲ ---

    return Scaffold(
      body: Column(
        children: [
          // フィルタリングUI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<MyListFilter>(
              segments: const [
                ButtonSegment<MyListFilter>(
                    value: MyListFilter.all, label: Text('すべて')),
                ButtonSegment<MyListFilter>(
                    value: MyListFilter.played, label: Text('通過済')),
                ButtonSegment<MyListFilter>(
                    value: MyListFilter.possessed, label: Text('所持')),
              ],
              selected: {currentFilter},
              onSelectionChanged: (Set<MyListFilter> newSelection) {
                ref.read(myListFilterProvider.notifier).state =
                    newSelection.first;
              },
            ),
          ),
          
          // --- ▼ 追加 ▼ ---
          // 並び替えUI (要件 1.2.7)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('並び替え: ', style: Theme.of(context).textTheme.bodySmall),
                DropdownButton<MyListSortOrder>(
                  value: currentSort,
                  style: Theme.of(context).textTheme.bodySmall,
                  underline: Container(), // 下線を消す
                  items: const [
                    DropdownMenuItem(
                      value: MyListSortOrder.dateAdded,
                      child: Text('登録順'),
                    ),
                    DropdownMenuItem(
                      value: MyListSortOrder.titleAsc,
                      child: Text('タイトル順'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(myListSortProvider.notifier).state = value;
                    }
                  },
                ),
              ],
            ),
          ),
          // --- ▲ 追加 ▲ ---

          // シナリオリスト
          Expanded(
            child: state.scenarios.when( // .when は AsyncValue に対して使う
              data: (_) { // データ（_）は filteredMyListProvider から取得
                if (scenarios.isEmpty) {
                  return Center(
                    child: Text(
                      currentFilter == MyListFilter.all
                          ? '[探す] タブからシナリオを登録できます'
                          : '該当するシナリオがありません',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: scenarios.length,
                  itemBuilder: (context, index) {
                    final item = scenarios[index];
                    return LogbookListItem(
                      scenarioId: item.id,
                      title: item.title,
                      authorName: item.authorName,
                      isPlayed: item.isPlayed,
                      isPossessed: item.isPossessed,
                      sourcePage: 'myList', // 更新ロジックの分岐用
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラー: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
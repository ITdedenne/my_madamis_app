// lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart';
// --- ▼ 修正 ▼ ---
// LogbookListItem の import を復活させる
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/logbook_list_item.dart';
// --- ▲ 修正 ▲ ---
import 'package:my_madamis_app/models/ModelProvider.dart';

class SearchScenariosPage extends ConsumerWidget {
  const SearchScenariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ViewModelの状態（ロード状態、データ）を監視
    final SearchScenariosState state =
        ref.watch(searchScenariosViewModelProvider);
    
    // 現在のフィルタ状態
    final currentFilter = ref.watch(searchFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          // 検索・フィルターバー
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: currentFilter.keyword,
                    decoration: const InputDecoration(
                      hintText: 'タイトル、作者名で検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.zero,
                    ),
                    // 入力が完了した（キーボードの完了ボタンを押した）時
                    onFieldSubmitted: (value) {
                      ref.read(searchFilterProvider.notifier).update(
                            (state) => state.copyWith(keyword: value),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => const FilterBottomSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // シナリオリスト
          Expanded(
            child: state.scenarios.when(
              // --- ▼ 修正 ▼ ---
              // (scenarios) は List<ScenarioWithMyStatus>型
              data: (List<ScenarioWithMyStatus> scenarios) { 
              // --- ▲ 修正 ▲ ---
                if (scenarios.isEmpty) {
                  return const Center(child: Text('シナリオが見つかりません'));
                }
                return ListView.builder(
                  itemCount: scenarios.length,
                  itemBuilder: (context, index) {
                    // --- ▼ 修正 ▼ ---
                    // item は ScenarioWithMyStatus
final item = scenarios[index]; // item は ScenarioWithMyStatus
return LogbookListItem(
  scenarioId: item.id,
  title: item.title,
  authorName: item.author?.authorName, // 'author' を介して 'authorName' を取得
  isPlayed: item.isPlayed,
  isPossessed: item.isPossessed,
  sourcePage: 'search', // 呼び出し元を 'search' と指定
);
                    // --- ▲ 修正 ▲ ---
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
// ファイルパス: lib/features/group_search/presentation/pages/group_search_results_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_results_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

class GroupSearchResultsPage extends ConsumerWidget {
  final List<String> friendIds;

  const GroupSearchResultsPage({super.key, required this.friendIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(groupSearchResultsProvider(friendIds));
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('グループ検索結果')),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('検索エラー: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
        data: (scenarios) {
          if (scenarios.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '条件に合うシナリオは見つかりませんでした。\n全員が未通過で、かつあなたが所持/GM希望のシナリオはありません。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          // 要件 6.1.5: 表示パフォーマンス対策 (無限スクロール)
          // 簡易実装としてListView.builderを使用 (FlutterのListViewはデフォルトで遅延構築されるため要件を満たす)
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              final scenario = scenarios[index];
              // 検索結果画面でも自分のステータスは更新可能 (要件 4.5.2)
              final status = userStatuses[scenario.id]!;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ScenarioListItem(
                  scenario: scenario,
                  status: status,
                  isReadOnly: false,
                  onStatusChanged: (newStatus) {
                    ref.read(userScenarioStatusProvider.notifier)
                       .updateStatus(scenario.id, newStatus);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
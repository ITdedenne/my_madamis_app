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
        data: (items) {
          if (items.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final scenario = item.scenario;
              final status = userStatuses[scenario.id]!;
              
              // 通常のリストアイテムを表示するが、PL希望フラグがある場合は装飾する
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Stack(
                  children: [
                    ScenarioListItem(
                      scenario: scenario,
                      status: status,
                      isReadOnly: false,
                      onStatusChanged: (newStatus) {
                        ref.read(userScenarioStatusProvider.notifier)
                           .updateStatus(scenario.id, newStatus);
                      },
                    ),
                    // ★ 強調表示 (バッジ)
                    if (item.isFriendWantsToPlay)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.pinkAccent,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'フレンズ希望!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
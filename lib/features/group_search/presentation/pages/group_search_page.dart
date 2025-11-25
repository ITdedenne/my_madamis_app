// ファイルパス: lib/features/group_search/presentation/pages/group_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

class GroupSearchPage extends ConsumerWidget {
  const GroupSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupSearchViewModelProvider);
    final notifier = ref.read(groupSearchViewModelProvider.notifier);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('グループ検索')),
      body: Column(
        children: [
          // --- 上部: フレンズ選択エリア ---
          ExpansionTile(
            title: Text('フレンズを選択 (${state.selectedFriendIds.length}人)'),
            initiallyExpanded: state.searchResults == null, // 結果が出るまでは開いておく
            children: [
              // 絞り込み検索バー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '名前で絞り込み',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: notifier.updateFriendFilter,
                ),
              ),
              // フレンズリスト
              SizedBox(
                height: 250, // 固定高さでスクロールさせる
                child: state.isLoadingFriends
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: state.filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = state.filteredFriends[index];
                          final isSelected = state.selectedFriendIds.contains(friend.id);
                          final isDisabled = !isSelected && state.isSelectionLimitReached;

                          return CheckboxListTile(
                            value: isSelected,
                            enabled: !isDisabled,
                            title: Text(friend.username),
                            subtitle: Text('ID: ${friend.publicUserId}'),
                            secondary: CircleAvatar(
                              child: Text(friend.username.isNotEmpty ? friend.username[0] : '?'),
                            ),
                            onChanged: (value) {
                              if (isDisabled && value == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('最大8人までです')),
                                );
                              } else {
                                notifier.toggleSelection(friend.id);
                              }
                            },
                          );
                        },
                      ),
              ),
              // 検索ボタン
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.selectedFriendIds.isEmpty
                        ? null
                        : () => notifier.search(),
                    icon: const Icon(Icons.search),
                    label: Text('このメンバー(${state.selectedFriendIds.length + 1}人)で検索'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(12)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // --- 下部: 結果リスト ---
          Expanded(
            child: state.isSearching
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults == null
                    ? const Center(child: Text('メンバーを選んで検索してください'))
                    : state.searchResults!.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('条件に合うシナリオは見つかりませんでした。\n(人数制限 または 全員未通過の条件を満たしていません)'),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: state.searchResults!.length,
                            itemBuilder: (context, index) {
                              final item = state.searchResults![index];
                              final scenario = item.scenario;
                              final status = userStatuses[scenario.id] ?? const UserScenarioStatus();

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
                                    // 強調表示
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
                                              Icon(Icons.favorite, size: 10, color: Colors.white),
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
                          ),
          ),
        ],
      ),
    );
  }
}
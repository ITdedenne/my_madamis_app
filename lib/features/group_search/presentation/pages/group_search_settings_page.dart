// ファイルパス: lib/features/group_search/presentation/pages/group_search_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/pages/group_search_results_page.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_settings_viewmodel.dart';

class GroupSearchSettingsPage extends ConsumerWidget {
  const GroupSearchSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupSearchSettingsViewModelProvider);
    final notifier = ref.read(groupSearchSettingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('グループ検索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '一緒に遊ぶフレンズを選択してください (最大8人)\n現在の選択: ${state.selectedFriendIds.length}人',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.friends.isEmpty
                    ? const Center(child: Text('フレンズがいません'))
                    : ListView.builder(
                        itemCount: state.friends.length,
                        itemBuilder: (context, index) {
                          final friend = state.friends[index];
                          final isSelected = state.selectedFriendIds.contains(friend.id);
                          
                          // 選択不可状態（上限到達 かつ 未選択）
                          final isDisabled = !isSelected && state.isSelectionLimitReached;

                          return CheckboxListTile(
                            value: isSelected,
                            enabled: !isDisabled,
                            onChanged: (value) {
                              if (isDisabled && value == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('一度に検索できるフレンズは8人までです')),
                                );
                              } else {
                                notifier.toggleSelection(friend.id);
                              }
                            },
                            title: Text(friend.username),
                            subtitle: Text('ID: ${friend.publicUserId}'),
                            secondary: CircleAvatar(
                              child: Text(friend.username.isNotEmpty ? friend.username[0] : '?'),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.selectedFriendIds.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupSearchResultsPage(
                              friendIds: state.selectedFriendIds.toList(),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: Text('このメンバー(${state.selectedFriendIds.length + 1}人)で検索'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ファイルパス: lib/features/group_search/presentation/widgets/group_search_condition_area.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/friend_selection_card.dart';

class GroupSearchConditionArea extends ConsumerWidget {
  final bool isBottomSheet;

  const GroupSearchConditionArea({
    super.key,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupSearchViewModelProvider);
    final notifier = ref.read(groupSearchViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    
    ref.listen<GroupSearchState>(groupSearchViewModelProvider, (prev, next) {
      if (prev?.isSearching == true && next.isSearching == false && next.searchResults != null) {
        if (isBottomSheet && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });

    return Container(
      color: colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
              color: colorScheme.surfaceContainerLow,
            ),
            child: Row(
              children: [
                Icon(Icons.group, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'メンバー: 自分 + ${state.selectedFriendIds.length}人 (計${state.totalPlayers}人)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isBottomSheet)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          
          // フレンズ検索
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '名前でフレンズを検索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: notifier.updateFriendFilter,
            ),
          ),
          
          // フレンズ一覧グリッド
          Expanded(
            child: state.isLoadingFriends
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      childAspectRatio: 0.82, 
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: state.filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = state.filteredFriends[index];
                      final isSelected = state.selectedFriendIds.contains(friend.id);
                      final isLimitReached = !isSelected && state.isSelectionLimitReached;
                      return Opacity(
                        opacity: isLimitReached ? 0.5 : 1.0,
                        child: FriendSelectionCard(
                          user: friend,
                          isSelected: isSelected,
                          onTap: () {
                            if (isLimitReached) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('最大8人までです')),
                              );
                            } else {
                              notifier.toggleSelection(friend.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          
          const Divider(height: 1),
          
          // 検索実行ボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.selectedFriendIds.isEmpty ? null : () {
                   FocusScope.of(context).unfocus();
                   notifier.search();
                },
                icon: const Icon(Icons.search),
                label: const Text('このメンバーで検索', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
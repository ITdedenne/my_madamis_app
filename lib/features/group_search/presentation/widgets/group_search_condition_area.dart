// ファイルパス: lib/features/group_search/presentation/widgets/group_search_condition_area.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/friend_selection_card.dart';

class GroupSearchConditionArea extends ConsumerStatefulWidget {
  const GroupSearchConditionArea({super.key});

  @override
  ConsumerState<GroupSearchConditionArea> createState() => _GroupSearchConditionAreaState();
}

class _GroupSearchConditionAreaState extends ConsumerState<GroupSearchConditionArea> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupSearchViewModelProvider);
    final notifier = ref.read(groupSearchViewModelProvider.notifier);
    
    // 検索完了時に自動で閉じるロジック
    ref.listen<GroupSearchState>(groupSearchViewModelProvider, (prev, next) {
      if (prev?.isSearching == true && next.isSearching == false && next.searchResults != null) {
        setState(() => _isExpanded = false);
      }
      if (next.searchResults == null && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    });

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            if (!_isExpanded)
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダーバー (常に表示)
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Row(
                  children: [
                    Icon(Icons.group, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'メンバー: 自分 + ${state.selectedFriendIds.length}人',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            
            // 詳細エリア (開閉)
            if (_isExpanded)
              Flexible( // 画面からはみ出ないように
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    // 高さ制限付きグリッド
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: state.isLoadingFriends
                          ? const Center(child: CircularProgressIndicator())
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 150,
                                childAspectRatio: 0.85,
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
              ),
          ],
        ),
      ),
    );
  }
}
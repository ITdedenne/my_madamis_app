// ファイルパス: lib/features/group_search/presentation/pages/group_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/friend_selection_card.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
// ↓ 新規作成するグリッドアイテムを使用
import 'package:my_madamis_app/features/group_search/presentation/widgets/group_scenario_grid_item.dart';

class GroupSearchPage extends ConsumerStatefulWidget {
  const GroupSearchPage({super.key});

  @override
  ConsumerState<GroupSearchPage> createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends ConsumerState<GroupSearchPage> {
  bool _isConditionExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupSearchViewModelProvider);
    final notifier = ref.read(groupSearchViewModelProvider.notifier);
    
    // 検索結果が出たら、デフォルトで条件エリアを閉じる（初回のみ）
    if (state.searchResults != null && _isConditionExpanded && !state.isSearching) {
        // ビルド完了後に閉じる
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) setState(() => _isConditionExpanded = false);
        });
    }
    
    // 検索結果がない（初期状態 or クリア後）場合は常に開く
    if (state.searchResults == null && !_isConditionExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) setState(() => _isConditionExpanded = true);
        });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('グループ検索')),
      body: Column(
        children: [
          // --- 条件エリア (アニメーション開閉) ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 条件サマリーバー (常に表示、タップで開閉)
                  InkWell(
                    onTap: () => setState(() => _isConditionExpanded = !_isConditionExpanded),
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
                          Icon(_isConditionExpanded ? Icons.expand_less : Icons.expand_more),
                        ],
                      ),
                    ),
                  ),
                  
                  // 詳細選択エリア (開いている時のみ)
                  if (_isConditionExpanded) ...[
                    // 検索バー
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
                    // フレンズリスト (高さ固定または比率)
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
                    // 検索実行ボタン
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: state.selectedFriendIds.isEmpty ? null : () => notifier.search(),
                          icon: const Icon(Icons.search),
                          label: const Text('このメンバーで検索', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // --- 検索結果エリア ---
          Expanded(
            child: state.isSearching
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults == null
                    ? const Center(child: Text('メンバーを選んで検索してください'))
                    : state.searchResults!.isEmpty
                        ? const Center(child: Text('条件に合うシナリオはありません'))
                        : Column(
                            children: [
                              // ソートバー
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.grey.shade50,
                                child: Row(
                                  children: [
                                    Text('${state.searchResults!.length} 件ヒット', style: TextStyle(color: Colors.grey.shade700)),
                                    const Spacer(),
                                    const Text('並び替え: '),
                                    DropdownButton<GroupSearchSortOrder>(
                                      value: state.sortOrder,
                                      isDense: true,
                                      underline: Container(),
                                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                      onChanged: (v) {
                                        if(v != null) notifier.changeSortOrder(v);
                                      },
                                      items: const [
                                        DropdownMenuItem(value: GroupSearchSortOrder.wantsToPlayDesc, child: Text('PL希望順')),
                                        DropdownMenuItem(value: GroupSearchSortOrder.externalGmDesc, child: Text('外部GM候補順')),
                                        DropdownMenuItem(value: GroupSearchSortOrder.titleAsc, child: Text('名前順')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              // グリッド結果
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // スマホ向け2列
                                    childAspectRatio: 0.75, // 少し縦長カード
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: state.searchResults!.length,
                                  itemBuilder: (context, index) {
                                    final item = state.searchResults![index];
                                    return GroupScenarioGridItem(item: item);
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
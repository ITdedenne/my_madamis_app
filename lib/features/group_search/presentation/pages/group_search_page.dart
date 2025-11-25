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

    // 結果を「遊べる」と「惜しい」に分割
    final playableItems = state.searchResults?.where((i) => i.isPlayable).toList() ?? [];
    final nearMissItems = state.searchResults?.where((i) => !i.isPlayable).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('グループ検索')),
      body: Column(
        children: [
          // --- 上部: フレンズ選択エリア (改善: 高さ制限を柔軟に) ---
          ExpansionTile(
            title: Text('フレンズを選択 (${state.selectedFriendIds.length}人)'),
            initiallyExpanded: state.searchResults == null, 
            children: [
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
              // ★ 改善: 固定高さではなく、画面割合に対する制約を使用
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4, // 画面の40%まで
                  minHeight: 100,
                ),
                child: state.isLoadingFriends
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        shrinkWrap: true, // 中身に応じて縮む
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          // --- 下部: 検索結果リスト ---
          Expanded(
            child: state.isSearching
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults == null
                    ? const Center(child: Text('メンバーを選んで検索してください'))
                    : ListView(
                        padding: const EdgeInsets.all(8.0),
                        children: [
                          // 1. 遊べるシナリオ
                          if (playableItems.isNotEmpty) ...[
                            _buildSectionHeader(context, '遊べるシナリオ (${playableItems.length}件)', Colors.green),
                            ...playableItems.map((item) => _buildResultItem(context, ref, item, userStatuses)),
                          ] else if (state.searchResults!.isNotEmpty) ...[
                             const Padding(
                               padding: EdgeInsets.all(16.0),
                               child: Text(
                                 '全員が未通過のシナリオはありませんでした。\n以下は、一部メンバーを除けば遊べる候補です。',
                                 textAlign: TextAlign.center,
                                 style: TextStyle(color: Colors.grey),
                               ),
                             ),
                          ],

                          // 2. 惜しいシナリオ (ゼロ件対策)
                          if (nearMissItems.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader(context, '惜しい！ (通過済あり)', Colors.grey),
                            ...nearMissItems.map((item) => _buildResultItem(context, ref, item, userStatuses, isNearMiss: true)),
                          ],
                          
                          if (state.searchResults!.isEmpty)
                             const Center(
                               child: Padding(
                                 padding: EdgeInsets.all(32.0),
                                 child: Text('条件に合うシナリオは見つかりませんでした。'),
                               ),
                             ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          Icon(Icons.label, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context, 
    WidgetRef ref, 
    GroupSearchDisplayItem item, 
    Map<String, UserScenarioStatus> userStatuses,
    {bool isNearMiss = false}
  ) {
    final scenario = item.scenario;
    final status = userStatuses[scenario.id] ?? const UserScenarioStatus();
    final opacity = isNearMiss ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Stack(
          children: [
            // 既存のCard内に詳細情報を追加する形でUIを構築
            Card(
              elevation: 0,
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  // 基本情報 (ScenarioListItemを再利用)
                  ScenarioListItem(
                    scenario: scenario,
                    status: status,
                    // 惜しいシナリオは詳細タップで理由を表示する
                    onTap: isNearMiss 
                        ? () => _showDetailDialog(context, '通過済みのメンバー', item.ngUserNames)
                        : null,
                    onStatusChanged: (newStatus) {
                      ref.read(userScenarioStatusProvider.notifier).updateStatus(scenario.id, newStatus);
                    },
                  ),
                  
                  // ★ 詳細情報エリア (誰が希望しているか等)
                  if (item.hasWantsToPlay || item.possessedNames.isNotEmpty || item.wantsToGmNames.isNotEmpty || isNearMiss) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.hasWantsToPlay)
                            _buildInfoRow(context, Icons.favorite, Colors.pink, 'PL希望', item.wantsToPlayNames),
                          
                          if (item.possessedNames.isNotEmpty)
                            _buildInfoRow(context, Icons.book, Colors.blue, '所持', item.possessedNames),
                            
                          if (item.wantsToGmNames.isNotEmpty)
                            _buildInfoRow(context, Icons.shopping_cart, Colors.orange, '検討', item.wantsToGmNames),

                          if (isNearMiss && item.ngUserNames.isNotEmpty)
                            _buildInfoRow(context, Icons.block, Colors.grey, '通過済', item.ngUserNames),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 右上の強調バッジ (PlayableかつPL希望者がいる場合)
            if (!isNearMiss && item.hasWantsToPlay)
              Positioned(
                top: 0,
                right: 0,
                child: _buildBadge(
                  context: context,
                  color: Colors.pinkAccent,
                  text: 'みんなで遊ぼう!',
                  onTap: () => _showDetailDialog(context, 'PL希望のメンバー', item.wantsToPlayNames),
                ),
              ),
              
            // 惜しい場合のバッジ
            if (isNearMiss)
              Positioned(
                top: 0,
                right: item.hasWantsToPlay ? 90 : 0,
                child: _buildBadge(
                  context: context,
                  color: Colors.grey, 
                  text: '${item.ngUserNames.length}名が通過済',
                  onTap: () => _showDetailDialog(context, '通過済みのメンバー', item.ngUserNames),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ★ タップして詳細を見る機能を追加した行ウィジェット
  Widget _buildInfoRow(BuildContext context, IconData icon, Color color, String label, List<String> names) {
    // 省略表示ロジック
    String namesText;
    bool isTruncated = false;
    
    if (names.length <= 2) {
      namesText = names.join(', ');
    } else {
      namesText = '${names[0]}, ${names[1]} 他${names.length - 2}名';
      isTruncated = true;
    }

    return InkWell(
      onTap: () => _showDetailDialog(context, '$labelのメンバー', names),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      namesText,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isTruncated || names.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ タップ可能なバッジ
  Widget _buildBadge({
    required BuildContext context,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              const Icon(Icons.info_outline, color: Colors.white, size: 10),
            ]
          ],
        ),
      ),
    );
  }

  // ★ 共通詳細ダイアログ
  void _showDetailDialog(BuildContext context, String title, List<String> names) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: names.map((n) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('・ $n', style: const TextStyle(fontSize: 16)),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }
}
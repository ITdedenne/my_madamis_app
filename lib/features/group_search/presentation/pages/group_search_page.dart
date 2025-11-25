// ファイルパス: lib/features/group_search/presentation/pages/group_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/friend_selection_card.dart'; // 新規作成したWidget
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

    // 検索結果があるかどうかでモードを判定
    final hasResults = state.searchResults != null;
    // 画面サイズ取得
    final size = MediaQuery.of(context).size;
    
    // フレンズエリアの高さ計算 (検索時は小さく、選択時は大きく)
    // ヘッダーや検索バーの分を引いて、適切な割合を設定
    final double friendAreaHeight = hasResults 
        ? 180.0  // 検索後: 小さく（1行程度見える高さ）
        : size.height * 0.65; // 検索前: 大きく（画面の65%）

    final playableItems = state.searchResults?.where((i) => i.isPlayable).toList() ?? [];
    final nearMissItems = state.searchResults?.where((i) => !i.isPlayable).toList() ?? [];

    return Scaffold(
      // キーボードが出たときにレイアウトが崩れないように調整
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('グループ検索'),
        actions: [
          if (hasResults)
            TextButton.icon(
              onPressed: () => notifier.clearResults(),
              icon: const Icon(Icons.refresh),
              label: const Text('条件変更'),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- 上部エリア: フレンズ選択 & 検索 ---
          // AnimatedContainerで高さの変化をスムーズにする
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: friendAreaHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                if (hasResults) // 検索結果が出ている時は影をつけて分離感を出す
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              children: [
                // フレンズ検索バー (名前フィルタ)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '名前でフレンズを絞り込み',
                      prefixIcon: const Icon(Icons.person_search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    onChanged: notifier.updateFriendFilter,
                  ),
                ),
                
                // 選択人数インジケーター
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '参加メンバー: 自分 + ${state.selectedFriendIds.length}人',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (state.isSelectionLimitReached)
                        const Text(
                          '最大8人まで',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                    ],
                  ),
                ),

                // フレンズグリッド
                Expanded(
                  child: state.isLoadingFriends
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 160, // カードの最大幅
                            childAspectRatio: 0.85,  // 縦横比 (少し縦長)
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: state.filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = state.filteredFriends[index];
                            final isSelected = state.selectedFriendIds.contains(friend.id);
                            final isLimitReached = !isSelected && state.isSelectionLimitReached;

                            return Opacity(
                              opacity: isLimitReached ? 0.5 : 1.0, // 選択不可なら薄くする
                              child: FriendSelectionCard(
                                user: friend,
                                isSelected: isSelected,
                                onTap: () {
                                  if (isLimitReached) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('これ以上選択できません')),
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
                
                // 検索実行ボタン (検索結果がない時のみ大きく表示)
                if (!hasResults)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: state.selectedFriendIds.isEmpty
                            ? null
                            : () {
                                // キーボードを閉じる
                                FocusScope.of(context).unfocus();
                                notifier.search();
                              },
                        icon: const Icon(Icons.search_rounded),
                        label: Text(
                          'このメンバーで検索',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- 下部エリア: 検索結果リスト ---
          // 検索実行時のみ表示される
          if (hasResults)
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: state.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : state.searchResults!.isEmpty
                        ? const Center(child: Text('条件に合うシナリオはありませんでした'))
                        : ListView(
                            padding: const EdgeInsets.all(12.0),
                            children: [
                              if (playableItems.isNotEmpty) ...[
                                _buildSectionHeader(context, '遊べるシナリオ (${playableItems.length}件)', Colors.green),
                                ...playableItems.map((item) => _buildResultItem(context, ref, item, userStatuses)),
                              ],
                              
                              if (nearMissItems.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                _buildSectionHeader(context, '惜しい！ (通過済あり)', Colors.grey),
                                ...nearMissItems.map((item) => _buildResultItem(context, ref, item, userStatuses, isNearMiss: true)),
                              ],
                            ],
                          ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Container(
            width: 4, 
            height: 20, 
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
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
    
    // 惜しいシナリオは少し背景をグレーにするなどの調整
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Stack(
        children: [
          Card(
            elevation: 0,
            color: isNearMiss 
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4) 
                : Theme.of(context).colorScheme.surfaceContainerLow,
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
                  onTap: isNearMiss 
                      ? () => _showDetailDialog(context, '通過済みのメンバー', item.ngUserNames)
                      : null,
                  onStatusChanged: (newStatus) {
                    ref.read(userScenarioStatusProvider.notifier).updateStatus(scenario.id, newStatus);
                  },
                ),
                
                // 詳細情報エリア
                if (item.hasWantsToPlay || item.possessedNames.isNotEmpty || item.wantsToGmNames.isNotEmpty || isNearMiss) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
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
            
          if (isNearMiss)
            Positioned(
              top: 0,
              right: item.hasWantsToPlay ? 110 : 0,
              child: _buildBadge(
                context: context,
                color: Colors.grey.shade600, 
                text: '${item.ngUserNames.length}名が通過済',
                onTap: () => _showDetailDialog(context, '通過済みのメンバー', item.ngUserNames),
              ),
            ),
        ],
      ),
    );
  }

  // タップ可能な情報行
  Widget _buildInfoRow(BuildContext context, IconData icon, Color color, String label, List<String> names) {
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
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
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

  Widget _buildBadge({
    required BuildContext context,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, color: Colors.white, size: 12),
            ]
          ],
        ),
      ),
    );
  }

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
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(n, style: const TextStyle(fontSize: 16)),
                ],
              ),
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
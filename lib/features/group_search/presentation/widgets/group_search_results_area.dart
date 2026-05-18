// ファイルパス: lib/features/group_search/presentation/widgets/group_search_results_area.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/group_scenario_card.dart';

const double _kMobileBreakpoint = 600.0;
const double _kMinCardWidth = 300.0;
const double _kGridAspectRatio = 2.0; 
const double _kGridSpacing = 16.0;
const double _kListSpacing = 8.0;

class GroupSearchResultsArea extends ConsumerWidget {
  const GroupSearchResultsArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupSearchViewModelProvider);
    final notifier = ref.read(groupSearchViewModelProvider.notifier);

    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('検索中にエラーが発生しました', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text(state.errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (state.searchResults == null) {
      return const Center(child: Text('メンバーを選んで検索してください'));
    }
    if (state.searchResults!.isEmpty) {
      return const Center(child: Text('条件に合うシナリオはありません'));
    }

    Iterable<GroupSearchDisplayItem> playableIter = state.searchResults!.where((i) => i.isPlayable);
    Iterable<GroupSearchDisplayItem> nearMissIter = state.searchResults!.where((i) => !i.isPlayable);

    if (state.exactPlayerMatch) {
      playableIter = playableIter.where((i) => i.isPlayerCountMatch);
      nearMissIter = nearMissIter.where((i) => i.isPlayerCountMatch);
    }

    final playableItems = playableIter.toList();
    final nearMissItems = nearMissIter.toList();

    final displayTargetPlayers = state.hasInternalGm ? state.totalPlayers - 1 : state.totalPlayers;

    return Column(
      children: [
        // ソート・フィルターバー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          width: double.infinity,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${playableItems.length + nearMissItems.length} 件ヒット', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)
                  ),
                  const Spacer(),
                  // ★ 追加: 身内GM（内部GM）トグルボタン
                  FilterChip(
                    label: const Text('身内GM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: state.hasInternalGm,
                    onSelected: notifier.toggleHasInternalGm,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.assignment_ind,
                      size: 16,
                      color: state.hasInternalGm ? Theme.of(context).colorScheme.onSecondaryContainer : Colors.grey,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    tooltip: 'メンバーの1人がGMを担当する',
                  ),
                  const SizedBox(width: 12),
                  // ソート
                  DropdownButton<GroupSearchSortOrder>(
                    value: state.sortOrder,
                    isDense: true,
                    underline: const SizedBox(),
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                    onChanged: (v) { if (v != null) notifier.changeSortOrder(v); },
                    items: const [
                      DropdownMenuItem(value: GroupSearchSortOrder.wantsToPlayDesc, child: Text('❤️ PL希望順')),
                      DropdownMenuItem(value: GroupSearchSortOrder.possessedDesc, child: Text('📚 所持順')),
                      DropdownMenuItem(value: GroupSearchSortOrder.wantsToGmDesc, child: Text('🛒 購入検討順')),
                      DropdownMenuItem(value: GroupSearchSortOrder.externalGmDesc, child: Text('👤 GM候補順(合算)')),
                      DropdownMenuItem(value: GroupSearchSortOrder.titleAsc, child: Text('📝 名前順')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ピッタリ人数フィルター (SegmentedButton)
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: [
                    const ButtonSegment(value: false, label: Text('すべて (惜しい含む)', style: TextStyle(fontSize: 12))),
                    ButtonSegment(
                      value: true, 
                      label: Text('${displayTargetPlayers}人用のみ', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {state.exactPlayerMatch},
                  onSelectionChanged: (Set<bool> newSelection) {
                    notifier.toggleExactPlayerMatch(newSelection.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // メインのリスト部分
        Expanded(
          child: (playableItems.isEmpty && nearMissItems.isEmpty) 
            ? const Center(child: Text('条件に合うシナリオはありません'))
            : LayoutBuilder(
            builder: (context, constraints) {
              final isPC = constraints.maxWidth >= _kMobileBreakpoint;
              final crossAxisCount = isPC ? (constraints.maxWidth / _kMinCardWidth).floor() : 1;
              
              if (isPC) {
                return Padding(
                  padding: const EdgeInsets.all(_kGridSpacing),
                  child: CustomScrollView(
                    slivers: [
                      if (playableItems.isNotEmpty) ...[
                         const SliverToBoxAdapter(child: _SectionHeader(title: '遊べるシナリオ', color: Colors.green)),
                         SliverGrid(
                           delegate: SliverChildBuilderDelegate(
                             (ctx, i) => GroupScenarioCard(item: playableItems[i]),
                             childCount: playableItems.length,
                           ),
                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                             crossAxisCount: crossAxisCount,
                             childAspectRatio: _kGridAspectRatio,
                             crossAxisSpacing: _kGridSpacing,
                             mainAxisSpacing: _kGridSpacing,
                           ),
                         ),
                         const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                      if (nearMissItems.isNotEmpty) ...[
                         const SliverToBoxAdapter(child: _SectionHeader(title: '惜しい！ (通過済あり・人数超過)', color: Colors.grey)),
                         SliverGrid(
                           delegate: SliverChildBuilderDelegate(
                             (ctx, i) => GroupScenarioCard(item: nearMissItems[i], isNearMiss: true),
                             childCount: nearMissItems.length,
                           ),
                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                             crossAxisCount: crossAxisCount,
                             childAspectRatio: _kGridAspectRatio,
                             crossAxisSpacing: _kGridSpacing,
                             mainAxisSpacing: _kGridSpacing,
                           ),
                         ),
                      ],
                    ],
                  ),
                );
              } else {
                return ListView(
                  padding: const EdgeInsets.all(_kListSpacing),
                  children: [
                    if (playableItems.isNotEmpty) ...[
                      const _SectionHeader(title: '遊べるシナリオ', color: Colors.green),
                      ...playableItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: _kListSpacing),
                        child: GroupScenarioCard(item: item),
                      )),
                      const SizedBox(height: 24),
                    ],
                    if (nearMissItems.isNotEmpty) ...[
                      const _SectionHeader(title: '惜しい！ (通過済あり・人数超過)', color: Colors.grey),
                       ...nearMissItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: _kListSpacing),
                        child: GroupScenarioCard(item: item, isNearMiss: true),
                      )),
                    ],
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
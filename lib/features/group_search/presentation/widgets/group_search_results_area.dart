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
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (state.searchResults == null) {
      return const Expanded(child: Center(child: Text('メンバーを選んで検索してください')));
    }
    if (state.searchResults!.isEmpty) {
      return const Expanded(child: Center(child: Text('条件に合うシナリオはありません')));
    }

    final playableItems = state.searchResults!.where((i) => i.isPlayable).toList();
    final nearMissItems = state.searchResults!.where((i) => !i.isPlayable).toList();

    return Expanded(
      child: Column(
        children: [
          // ソートバー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Text('${state.searchResults!.length} 件ヒット', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const Spacer(),
                DropdownButton<GroupSearchSortOrder>(
                  value: state.sortOrder,
                  isDense: true,
                  underline: Container(),
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  onChanged: (v) { if (v != null) notifier.changeSortOrder(v); },
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
          
          // 結果リスト (レスポンシブ)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isPC = constraints.maxWidth >= _kMobileBreakpoint;
                final crossAxisCount = isPC ? (constraints.maxWidth / _kMinCardWidth).floor() : 1;
                
                if (isPC) {
                  // ★ 修正: CustomScrollViewのpaddingを削除し、Paddingウィジェットでラップ
                  return Padding(
                    padding: const EdgeInsets.all(_kGridSpacing),
                    child: CustomScrollView(
                      slivers: [
                        if (playableItems.isNotEmpty) ...[
                           SliverToBoxAdapter(child: _SectionHeader(title: '遊べるシナリオ', color: Colors.green)),
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
                           SliverToBoxAdapter(child: _SectionHeader(title: '惜しい！ (通過済あり)', color: Colors.grey)),
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
                  // スマホ: ListView
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
                        const _SectionHeader(title: '惜しい！ (通過済あり)', color: Colors.grey),
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
      ),
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
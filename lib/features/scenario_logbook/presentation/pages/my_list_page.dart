import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

// --- デザイン定数 ---
const double _kMobileBreakpoint = 600.0;
const double _kMinCardWidth = 300.0;
const double _kGridAspectRatio = 2.0;    // PC: かなり横長 (テキスト専用に最適化)
const double _kGridSpacing = 16.0;
const double _kListSpacing = 12.0; // リスト表示時の間隔
const double _kSummaryPadding = 16.0;
const double _kSummaryFontSize = 14.0;

class MyListPage extends ConsumerStatefulWidget {
  const MyListPage({super.key});

  @override
  ConsumerState<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends ConsumerState<MyListPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      ref.read(myListPageStateProvider.notifier).update((state) => 
        state.copyWith(filter: MyListFilter.values[_tabController.index]));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageNotifier = ref.read(myListPageStateProvider.notifier);

    return Scaffold(
      // ScaffoldのbodyにColumnを置く形でも良いですが、
      // NestedScrollViewを使うとタブバーもスクロールに連動させられます。
      // ここではシンプルにColumn構成にします。
      body: Column(
        children: [
          // 上部コントロールエリア
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start, // 左寄せ
                    tabs: const [
                      Tab(text: 'すべて'),
                      Tab(text: '通過済'),
                      Tab(text: '所持'),
                      Tab(text: 'GM検討'),
                    ],
                  ),
                ),
                PopupMenuButton<SortOrder>(
                  icon: const Icon(Icons.sort),
                  tooltip: '並び替え',
                  onSelected: (newOrder) => pageNotifier.update((state) => state.copyWith(sortOrder: newOrder)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: SortOrder.byTitle, child: Text('シナリオ名順')),
                    const PopupMenuItem(value: SortOrder.byAuthor, child: Text('作者名順')),
                  ],
                )
              ],
            ),
          ),
          
          // コンテンツエリア
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(userScenarioStatusProvider.notifier).refresh();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildContent(context, constraints.maxWidth);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double screenWidth) {
    final myListAsync = ref.watch(filteredAndSortedMyListProvider);
    final pageState = ref.watch(myListPageStateProvider);

    return myListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('エラー: $e')),
      data: (myList) {
        if (myList.isEmpty) {
          return _buildEmptyState(pageState.filter);
        }

        // レスポンシブ設定
        final isPC = screenWidth >= _kMobileBreakpoint;
        final int crossAxisCount = isPC ? (screenWidth / _kMinCardWidth).floor() : 1;
        
        return CustomScrollView(
          slivers: [
            // 1. サマリー表示 (Dashboard)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(_kSummaryPadding),
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${myList.length} 件のシナリオが見つかりました',
                      style: TextStyle(
                        color: Colors.grey[600], 
                        fontSize: _kSummaryFontSize,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. グリッド/リスト表示
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _kGridSpacing),
              sliver: isPC
                  // PC: グリッド表示
                  ? SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                        childAspectRatio: _kGridAspectRatio,
                        crossAxisSpacing: _kGridSpacing,
                        mainAxisSpacing: _kGridSpacing,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildItem(myList[index]),
                        childCount: myList.length,
                      ),
                    )
                  // スマホ: リスト表示 (SliverList)
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: _kListSpacing),
                          child: _buildItem(myList[index]),
                        ),
                        childCount: myList.length,
                      ),
                    ),
            ),
            
            // 下部の余白
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }

  Widget _buildItem(UserScenario userScenario) {
    return ScenarioListItem(
      scenario: userScenario.scenario,
      status: userScenario.status,
      onStatusChanged: (newStatus) {
        ref.read(userScenarioStatusProvider.notifier)
           .updateStatus(userScenario.scenario.id, newStatus);
      },
    );
  }

  Widget _buildEmptyState(MyListFilter filter) {
    final message = switch (filter) {
      MyListFilter.all => '記録されたシナリオはありません。\n「探す」画面から追加しましょう！',
      MyListFilter.played => '「通過済」のシナリオはありません。',
      MyListFilter.possessed => '「所持」しているシナリオはありません。',
      MyListFilter.wantsToGm => '「GM検討中」のシナリオはありません。',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
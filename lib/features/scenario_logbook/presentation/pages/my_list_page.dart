// ファイルパス: lib/features/scenario_logbook/presentation/pages/my_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      ref.read(myListPageStateProvider.notifier).update((state) => state.copyWith(filter: MyListFilter.values[_tabController.index]));
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'すべて'),
                    Tab(text: '通過済'),
                    Tab(text: '所持'),
                  ],
                  labelColor: Theme.of(context).primaryColor, // UI調整
                  unselectedLabelColor: Colors.grey, // UI調整
                  indicatorColor: Theme.of(context).primaryColor, // UI調整
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // ★修正: allScenariosProviderも明示的に再取得を依頼
              ref.invalidate(allScenariosProvider);
              // userScenarioStatusProviderは内部でfetchMyListを呼ぶので、こちらもリフレッシュ
              await ref.read(userScenarioStatusProvider.notifier).refresh();
              // allScenariosProviderの解決を待つ
              await ref.read(allScenariosProvider.future);
            },
            child: _buildBody(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final pageState = ref.watch(myListPageStateProvider);
    // Providerの型をAsyncValueで監視
    final groupedScenariosAsync = ref.watch(filteredAndSortedMyListProvider);
    final allScenariosAsync = ref.watch(allScenariosProvider);

    // allScenariosProviderがロード中の場合
    if (allScenariosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // allScenariosProviderがエラーの場合（このエラーがユーザーが遭遇しているエラー）
    if (allScenariosAsync.hasError) {
      return Center(child: Text('シナリオデータのロード中にエラーが発生しました: ${allScenariosAsync.error}'));
    }
    
    // ここから先はデータがロードされた後
    final groupedScenarios = groupedScenariosAsync; // Map<String, List<UserScenario>>

    if (groupedScenarios.isEmpty) {
      final message = switch (pageState.filter) {
        MyListFilter.all => '記録されたシナリオはありません。\n「探す」タブから追加しましょう！',
        MyListFilter.played => '「通過済」のシナリオはありません。',
        MyListFilter.possessed => '「所持」しているシナリオはありません。',
      };
      return Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final groupKeys = groupedScenarios.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final groupKey = groupKeys[index];
        final scenariosInGroup = groupedScenarios[groupKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                groupKey,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...scenariosInGroup.map((userScenario) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(userScenario.scenario.title),
                  subtitle: Text(userScenario.scenario.authorName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 通過済アイコン
                      if (userScenario.status.isPlayed)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      if (userScenario.status.isPlayed && userScenario.status.isPossessed)
                        const SizedBox(width: 8),
                      // 所持アイコン
                      if (userScenario.status.isPossessed)
                        const Icon(Icons.book, color: Colors.blue, size: 20),
                    ],
                  ),
                  onTap: () {
                    // TODO: Scenarioの詳細画面に遷移するロジックを実装
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
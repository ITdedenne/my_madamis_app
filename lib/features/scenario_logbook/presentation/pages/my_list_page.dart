// ファイルパス: lib/features/scenario_logbook/presentation/pages/my_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/providers.dart'; // ★修正: Providerを参照するために必要

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
              // ★修正: DBから初期データを読み込むFutureProviderを強制的に無効化し、再読み込みをトリガー
              ref.invalidate(initialStatusMapProvider);
              // マイリストの本体データも無効化し、最新のDBデータを再取得させる
              ref.invalidate(getMyListUseCaseProvider); 
              
              // データの再取得が完了するのを待つ (UIの更新はNotifierとFutureProviderの監視に任せる)
              await ref.read(initialStatusMapProvider.future);
            },
            child: _buildBody(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final pageState = ref.watch(myListPageStateProvider);
    // ★修正: filteredAndSortedMyListProvider は、DBの最新データに依存する Providerである必要があります。
    // UserScenarioStatusProviderが更新されたタイミングで、 filteredAndSortedMyListProvider が
    // 依存しているデータソース（例: getMyListUseCaseProvider）が再実行されるように、
    // lib/providers.dart での定義が必要です。ここでは、そのリアクティブなデータソースを監視していると仮定します。
    final groupedScenariosAsync = ref.watch(filteredAndSortedMyListProvider);
    final allScenariosAsync = ref.watch(allScenariosProvider);

    // allScenariosProvider が最新のデータを持っていると仮定し、loadingとerrorをチェックします。
    if (allScenariosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (allScenariosAsync.hasError) {
      return Center(child: Text('エラーが発生しました: ${allScenariosAsync.error}'));
    }
    
    // データはAsyncValueではないMap/Listの形を想定
    if (groupedScenariosAsync.isEmpty) {
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

    final groupKeys = groupedScenariosAsync.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final groupKey = groupKeys[index];
        final scenariosInGroup = groupedScenariosAsync[groupKey]!;
        
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
                      if (userScenario.status.isPlayed)
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (userScenario.status.isPlayed && userScenario.status.isPossessed)
                        const SizedBox(width: 8),
                      if (userScenario.status.isPossessed)
                        const Icon(Icons.book, color: Colors.blue),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
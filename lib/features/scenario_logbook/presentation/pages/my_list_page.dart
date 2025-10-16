// ファイルパス: lib/features/scenario_logbook/presentation/pages/my_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ref.read(myListViewModelProvider.notifier).setFilter(MyListFilter.values[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myListViewModelProvider);
    final notifier = ref.read(myListViewModelProvider.notifier);

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
                onSelected: notifier.setSortOrder,
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
            onRefresh: () => notifier.fetchMyList(),
            child: _buildBody(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, MyListState state) {
    if (state.isLoading && state.allUserScenarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return Center(child: Text('エラーが発生しました: ${state.errorMessage}'));
    }
    
    final groupedScenarios = state.groupedScenarios;

    if (groupedScenarios.isEmpty) {
      final message = switch (state.filter) {
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
            // 頭文字ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                groupKey,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // グループ内のシナリオリスト
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
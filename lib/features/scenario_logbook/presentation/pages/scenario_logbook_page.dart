// ファイルパス: lib/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/my_list_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/search_scenarios_page.dart';

class ScenarioLogbookPage extends StatelessWidget {
  const ScenarioLogbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TabController を使ってタブの状態を管理
    return DefaultTabController(
      length: 2, // タブの数
      child: Scaffold(
        appBar: AppBar(
          title: const Text('シナリオ手帳'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.search),
                text: '探す',
              ),
              Tab(
                icon: Icon(Icons.history_edu),
                text: 'マイリスト',
              ),
            ],
          ),
        ),
        // TabBarView を使ってタブに応じた画面を表示
        body: const TabBarView(
          children: [
            SearchScenariosPage(), // 0番目のタブ
            MyListPage(),          // 1番目のタブ
          ],
        ),
      ),
    );
  }
}
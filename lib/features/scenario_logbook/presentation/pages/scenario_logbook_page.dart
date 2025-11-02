// lib/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/my_list_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/search_scenarios_page.dart';

class ScenarioLogbookPage extends StatelessWidget {
  const ScenarioLogbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('シナリオ手帳'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '探す'),
              Tab(text: 'マイリスト'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SearchScenariosPage(), // 修正後のPage
            MyListPage(),          // 修正後のPage
          ],
        ),
      ),
    );
  }
}
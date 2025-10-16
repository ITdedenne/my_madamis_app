// ファイルパス: lib/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/my_list_page.dart'; // <-- この行を追加
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/search_scenarios_page.dart';

// 「探す」と「マイリスト」をタブで切り替えるための親画面
class ScenarioLogbookPage extends StatefulWidget {
  const ScenarioLogbookPage({super.key});

  @override
  State<ScenarioLogbookPage> createState() => _ScenarioLogbookPageState();
}

class _ScenarioLogbookPageState extends State<ScenarioLogbookPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const SearchScenariosPage(),
    const MyListPage(), // MyListPageクラスが解決され、エラーが解消されます
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '探す'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'マイリスト'),
        ],
      ),
    );
  }
}
// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ... ViewModelとWidgetのimport

// 「探す」画面のUI
class SearchScenariosPage extends ConsumerWidget {
  const SearchScenariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final viewModelState = ref.watch(searchScenariosViewModelProvider);
    // final notifier = ref.read(searchScenariosViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シナリオを探す'),
        // TODO: ここに検索バーや絞り込みボタンを配置
      ),
      body: ListView.builder(
        // itemCount: viewModelState.scenarios.length,
        itemCount: 50, // Dummy
        itemBuilder: (context, index) {
          // final scenario = viewModelState.scenarios[index];
          // return ScenarioListItem(scenario: scenario, ...);
          return ListTile(title: Text('シナリオ $index')); // Dummy
        },
      ),
    );
  }
}
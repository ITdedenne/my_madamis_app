// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

class SearchScenariosPage extends ConsumerStatefulWidget {
  const SearchScenariosPage({super.key});

  @override
  ConsumerState<SearchScenariosPage> createState() => _SearchScenariosPageState();
}

class _SearchScenariosPageState extends ConsumerState<SearchScenariosPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchScenariosViewModelProvider);
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);

    // `TabBarView` 内では `Scaffold` は不要
    return Column(
      children: [
        // 検索バー
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'シナリオ名で検索...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: notifier.onSearchTermChanged,
          ),
        ),
        // 本体（リスト）
        Expanded(child: _buildBody(state, notifier)),
        // 【変更点①】ページネーションUI
        if (!state.isLoading && state.scenarios.isNotEmpty)
          _buildPaginationControls(state, notifier),
      ],
    );
  }

  Widget _buildBody(SearchScenariosState state, SearchScenariosViewModel notifier) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null) return Center(child: Text('エラー: ${state.errorMessage}'));
    if (state.scenarios.isEmpty) return const Center(child: Text('シナリオが見つかりません。'));

    return ListView.builder(
      itemCount: state.scenarios.length,
      itemBuilder: (context, index) {
        final scenario = state.scenarios[index];
        return ScenarioListItem(
          scenario: scenario,
          status: state.myScenarioStatuses[scenario.id] ?? const UserScenarioStatus(),
          onStatusChanged: (newStatus) {
            notifier.updateStatus(scenario.id, newStatus);
          },
        );
      },
    );
  }

  // 【変更点②】ページ番号ボタンを生成するウィジェット
  Widget _buildPaginationControls(SearchScenariosState state, SearchScenariosViewModel notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(state.totalPages, (index) {
          final page = index + 1;
          return ElevatedButton(
            onPressed: state.currentPage == page ? null : () => notifier.goToPage(page),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.currentPage == page ? Colors.blue.shade100 : null,
            ),
            child: Text('$page'),
          );
        }),
      ),
    );
  }
}
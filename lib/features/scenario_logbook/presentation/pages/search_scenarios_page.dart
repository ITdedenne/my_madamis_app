// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart';
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
    ref.listen<SearchScenariosState>(searchScenariosViewModelProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(searchScenariosViewModelProvider.notifier).clearSuccessMessage();
      }
    });

    final state = ref.watch(searchScenariosViewModelProvider);
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);
    
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'シナリオ名・作者名で検索...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: notifier.onSearchTermChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: state.filter.isInitial ? Colors.grey : Theme.of(context).primaryColor, 
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FilterBottomSheet(
                      currentFilter: state.filter,
                      onApplyFilter: notifier.applyFilter,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        _buildFilterChips(state, notifier),
        Expanded(child: _buildBody(state, userStatuses)),
        
        // ★★★ 修正箇所: データが空でも、総ページ数が1より大きければPaginationControlsを表示 ★★★
        if (state.totalPages > 1 || state.currentPage > 1) 
          _buildPaginationControls(state, notifier),
      ],
    );
  }
  
  Widget _buildFilterChips(SearchScenariosState state, SearchScenariosViewModel notifier) {
    if (state.filter.isInitial) {
      return const SizedBox(height: 8);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 4.0,
        children: [
          if (state.filter.playerCountRange.start != 1 || state.filter.playerCountRange.end != 15)
            Chip(
              label: Text('${state.filter.playerCountRange.start.round()}-${state.filter.playerCountRange.end.round()}人'),
              onDeleted: () {
                final newFilter = SearchFilter(
                  playerCountRange: const RangeValues(1, 15),
                  gmRequirement: state.filter.gmRequirement,
                  authorName: state.filter.authorName,
                );
                notifier.applyFilter(newFilter);
              },
            ),
          if (state.filter.gmRequirement != null)
            Chip(
              label: Text('GM: ${state.filter.gmRequirement!.displayName}'),
              onDeleted: () {
                 final newFilter = SearchFilter(
                  playerCountRange: state.filter.playerCountRange,
                  gmRequirement: null,
                  authorName: state.filter.authorName,
                );
                notifier.applyFilter(newFilter);
              },
            ),
          if (state.filter.authorName != null)
            Chip(
              label: Text('作者: ${state.filter.authorName}'),
              onDeleted: () {
                 final newFilter = SearchFilter(
                  playerCountRange: state.filter.playerCountRange,
                  gmRequirement: state.filter.gmRequirement,
                  authorName: null,
                );
                notifier.applyFilter(newFilter);
              },
            ),
          ActionChip(
            label: const Text('全クリア'),
            onPressed: () {
              notifier.applyFilter(SearchFilter.initial());
            },
          )
        ],
      ),
    );
  }

  Widget _buildBody(SearchScenariosState state, Map<String, UserScenarioStatus> userStatuses) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null) return Center(child: Text('エラー: ${state.errorMessage}'));
    
    if (state.scenarios.isEmpty) {
        // ★修正: 2ページ目以降でデータがない場合のメッセージを調整 ★
        if (state.currentPage > 1) {
             return const Center(child: Text('このページにはシナリオがありません。\n戻るか、フィルターを変更してください。'));
        }
        return const Center(child: Text('シナリオが見つかりません。'));
    }

    return ListView.builder(
      itemCount: state.scenarios.length,
      itemBuilder: (context, index) {
        final scenario = state.scenarios[index];
        return ScenarioListItem(
          scenario: scenario,
          status: userStatuses[scenario.id] ?? const UserScenarioStatus(),
          onStatusChanged: (newStatus) {
            ref.read(userScenarioStatusProvider.notifier).updateStatus(scenario.id, newStatus);
            ref.read(searchScenariosViewModelProvider.notifier).showSuccessMessage('手帳を更新しました');
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(SearchScenariosState state, SearchScenariosViewModel notifier) {
    // totalPagesが1以上のときに表示される
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 戻るボタン
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: state.currentPage > 1 ? () => notifier.goToPage(state.currentPage - 1) : null,
          ),
          const SizedBox(width: 16),
          // ページ番号表示（現在のページ / 総ページ数）
          Text('${state.currentPage} / ${state.totalPages}'),
          const SizedBox(width: 16),
          // 進むボタン
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            // ★修正: 現在のページがtotalPages未満で、かつViewModelに次のページのトークンが残っている場合に有効にする
            onPressed: state.currentPage < state.totalPages ? () => notifier.goToPage(state.currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
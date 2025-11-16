// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart'; // ★ 追加
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

    // ★ 修正: state -> searchState にリネーム (フィルターチップ表示用)
    final searchState = ref.watch(searchScenariosViewModelProvider);
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);
    
    // ★ 追加: フィルタリングされた結果(AsyncValue)を監視
    final scenariosAsync = ref.watch(filteredScenariosProvider);
    
    // ユーザーのステータス全体を監視
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
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FilterBottomSheet(
                      currentFilter: searchState.filter, // ★ 修正
                      onApplyFilter: notifier.applyFilter,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        _buildFilterChips(searchState, notifier), // ★ 修正
        // ★ 修正: _buildBody の呼び出し
        Expanded(child: _buildBody(context, scenariosAsync, userStatuses)),
        // ★ 修正: ページネーションコントロールを削除
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

  // ★ 修正: _buildBody のシグネチャと内容を変更
  Widget _buildBody(
    BuildContext context, 
    AsyncValue<List<Scenario>> scenariosAsync, 
    Map<String, UserScenarioStatus> userStatuses
  ) {
    // AsyncValue を .when でハンドリング
    return scenariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('エラー: ${e.toString()}')),
      data: (scenarios) {
        if (scenarios.isEmpty) {
          return const Center(child: Text('シナリオが見つかりません。'));
        }

        return ListView.builder(
          itemCount: scenarios.length,
          itemBuilder: (context, index) {
            final scenario = scenarios[index];
            return ScenarioListItem(
              scenario: scenario,
              status: userStatuses[scenario.id] ?? const UserScenarioStatus(),
              onStatusChanged: (newStatus) {
                // ステータス更新は一元管理されたNotifierに依頼
                ref.read(userScenarioStatusProvider.notifier).updateStatus(scenario.id, newStatus);
                ref.read(searchScenariosViewModelProvider.notifier).showSuccessMessage('手帳を更新しました');
              },
            );
          },
        );
      },
    );
  }

  // ★ 修正: _buildPaginationControls は不要になったため削除
}
// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

import '../../domain/entities/scenario.dart';

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
      // ★エラーメッセージのスナックバー表示を追加（任意）
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('エラー: ${next.errorMessage}'),
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 3),
           ),
         );
      }
    });

    final state = ref.watch(searchScenariosViewModelProvider);
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);

    // ★★★ 修正: AsyncValue<Map<String, UserScenarioStatus>> を watch する ★★★
    final userStatusesAsync = ref.watch(userScenarioStatusProvider);

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
        // ★★★ 修正: Expanded 内の _buildBody に AsyncValue を渡す ★★★
        Expanded(child: _buildBody(state, userStatusesAsync)),
        if (!state.isLoading && state.scenarios.isNotEmpty)
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

  // ★★★ 修正: 引数の型を AsyncValue<Map<String, UserScenarioStatus>> に変更 ★★★
  Widget _buildBody(SearchScenariosState searchState, AsyncValue<Map<String, UserScenarioStatus>> userStatusesAsync) {
    // searchState (シナリオリスト自体) のロード中・エラー表示
    if (searchState.isLoading) return const Center(child: CircularProgressIndicator());
    if (searchState.errorMessage != null) return Center(child: Text('シナリオ取得エラー: ${searchState.errorMessage}'));
    if (searchState.scenarios.isEmpty) return const Center(child: Text('シナリオが見つかりません。'));

    // userStatusesAsync (ステータスマップ) のロード中・エラー表示
    return userStatusesAsync.when(
      data: (userStatuses) {
        // ★★★ データがある場合は Map を使って ListView を構築 ★★★
        return ListView.builder(
          itemCount: searchState.scenarios.length,
          itemBuilder: (context, index) {
            final scenario = searchState.scenarios[index];
            return ScenarioListItem(
              scenario: scenario,
              status: userStatuses[scenario.id] ?? const UserScenarioStatus(), // Map からステータスを取得
              onStatusChanged: (newStatus) {
                // ステータス更新は一元管理されたNotifierに依頼
                ref.read(userScenarioStatusProvider.notifier).updateStatus(scenario.id, newStatus);
                ref.read(searchScenariosViewModelProvider.notifier).showSuccessMessage('手帳を更新しました');
              },
            );
          },
        );
      },
      // ★★★ ローディング中の表示 ★★★
      loading: () => const Center(child: CircularProgressIndicator()),
      // ★★★ エラー時の表示 ★★★
      error: (err, stack) => Center(child: Text('ステータス取得エラー: $err')),
    );
  }

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

// FilterBottomSheetで使うため、同ファイル内に移動またはimport
extension GmRequirementExtension on GmRequirement {
  String get displayName {
    switch (this) {
      case GmRequirement.required: return '必須';
      case GmRequirement.optional: return '任意';
      case GmRequirement.none: return '不要';
    }
  }
}
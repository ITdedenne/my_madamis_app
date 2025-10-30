// ファイルパス: lib/features/scenario_logbook/presentation/pages/search_scenarios_page.dart
// 内容: 【修正】

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
  
  // ★リッスンとNotifierの取得ロジックを build メソッド内に移動（StatelessWidgetの作法に準拠）

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

      // ★ 検索条件がリセットされたら、テキストフィールドもクリアする
      if (previous?.currentSearchTerm != next.currentSearchTerm && next.currentSearchTerm.isEmpty) {
        _searchController.clear();
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
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FilterBottomSheet(
                      currentFilter: state.filter,
                      onApplyFilter: (newFilter) {
                        // ★ 検索コントローラーのクリアを applyFilter に委ねる
                        if (_searchController.text.isNotEmpty) {
                          _searchController.clear();
                        }
                        notifier.applyFilter(newFilter);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        _buildFilterChips(state, notifier),
        Expanded(child: _buildBody(state, userStatuses)),
        // ★ ページネーションコントロールの表示条件を変更
        if (!state.isLoading && state.scenarios.isNotEmpty && (state.currentPageIndex > 0 || state.pageTokens.isNotEmpty))
          _buildPaginationControls(state, notifier),
      ],
    );
  }
  
  // _buildFilterChips メソッドは変更なし
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
              // ★ 検索コントローラーのクリアも行う
              if (_searchController.text.isNotEmpty) {
                _searchController.clear();
              }
              notifier.applyFilter(SearchFilter.initial());
            },
          )
        ],
      ),
    );
  }

  // _buildBody メソッドは変更なし
  Widget _buildBody(SearchScenariosState state, Map<String, UserScenarioStatus> userStatuses) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null) return Center(child: Text('エラー: ${state.errorMessage}'));
    if (state.scenarios.isEmpty) return const Center(child: Text('シナリオが見つかりません。'));

    return ListView.builder(
      itemCount: state.scenarios.length,
      itemBuilder: (context, index) {
        final scenario = state.scenarios[index];
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
  }

  // ★★★ _buildPaginationControls を大幅に修正 ★★★
  Widget _buildPaginationControls(SearchScenariosState state, SearchScenariosViewModel notifier) {
    
    // ページボタンの総数 = 1ページ目 + トークンの数
    int totalButtons = state.pageTokens.length + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(totalButtons, (index) {
          final page = index + 1;
          final bool isCurrentPage = state.currentPageIndex == index;

          return ElevatedButton(
            onPressed: isCurrentPage ? null : () => notifier.goToPage(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentPage ? Colors.blue.shade100 : null,
            ),
            child: Text('$page'),
          );
        }),
      ),
    );
  }
}
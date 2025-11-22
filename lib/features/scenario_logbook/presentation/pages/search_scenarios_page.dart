import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

// --- レイアウト定数 (Magic Numbersの排除) ---
const double _kMobileBreakpoint = 600.0; // スマホ/タブレット・PCの境界線
const double _kMinCardWidth = 300.0;     // グリッド表示時のカード最小幅
const double _kGridAspectRatio = 1.5;    // カードのアスペクト比 (3:2)
const double _kGridSpacing = 16.0;       // グリッド間のスペース
const double _kListSpacing = 8.0;        // リスト間のスペース
const double _kHorizontalPadding = 8.0;  // 画面左右のパディング

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

    final searchState = ref.watch(searchScenariosViewModelProvider);
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);
    final scenariosAsync = ref.watch(filteredScenariosProvider);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_kHorizontalPadding, 8, _kHorizontalPadding, 0),
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
                      currentFilter: searchState.filter,
                      onApplyFilter: notifier.applyFilter,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        _buildFilterChips(searchState, notifier),
        
        // メインコンテンツ部分
        Expanded(child: _buildBody(context, scenariosAsync, userStatuses)),
      ],
    );
  }
  
  Widget _buildFilterChips(SearchScenariosState state, SearchScenariosViewModel notifier) {
    if (state.filter.isInitial) {
      return const SizedBox(height: 8);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHorizontalPadding, vertical: 4.0),
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

  Widget _buildBody(
    BuildContext context, 
    AsyncValue<List<Scenario>> scenariosAsync, 
    Map<String, UserScenarioStatus> userStatuses
  ) {
    return scenariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('エラー: ${e.toString()}')),
      data: (scenarios) {
        if (scenarios.isEmpty) {
          return const Center(child: Text('シナリオが見つかりません。'));
        }

        // ★ レスポンシブレイアウトの適用
        return LayoutBuilder(
          builder: (context, constraints) {
            // 画面幅が境界値を超えている場合はグリッド表示 (PC/タブレット)
            if (constraints.maxWidth >= _kMobileBreakpoint) {
              // 画面幅に合わせて列数を計算（最低幅を確保）
              final crossAxisCount = (constraints.maxWidth / _kMinCardWidth).floor();
              
              return GridView.builder(
                padding: const EdgeInsets.all(_kGridSpacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1, // 安全策
                  childAspectRatio: _kGridAspectRatio, // カード比率 3:2
                  crossAxisSpacing: _kGridSpacing,
                  mainAxisSpacing: _kGridSpacing,
                ),
                itemCount: scenarios.length,
                itemBuilder: (context, index) => _buildScenarioItem(scenarios[index], userStatuses),
              );
            } 
            // 画面幅が狭い場合はリスト表示 (スマホ)
            else {
              return ListView.builder(
                padding: const EdgeInsets.all(_kListSpacing),
                itemCount: scenarios.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: _kListSpacing),
                  child: _buildScenarioItem(scenarios[index], userStatuses),
                ),
              );
            }
          },
        );
      },
    );
  }

  // グリッドとリストで共通して使うアイテム生成メソッド
  Widget _buildScenarioItem(Scenario scenario, Map<String, UserScenarioStatus> userStatuses) {
    return ScenarioListItem(
      scenario: scenario,
      status: userStatuses[scenario.id] ?? const UserScenarioStatus(),
      onStatusChanged: (newStatus) {
        ref.read(userScenarioStatusProvider.notifier).updateStatus(scenario.id, newStatus);
        ref.read(searchScenariosViewModelProvider.notifier).showSuccessMessage('手帳を更新しました');
      },
    );
  }
}
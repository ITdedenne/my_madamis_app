import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

// --- レイアウト定数 (Magic Numbersの排除) ---
const double _kMobileBreakpoint = 600.0;
const double _kMinCardWidth = 300.0;
const double _kGridAspectRatio = 2.0;    // PC: 2.0 (調整済み)
const double _kGridSpacing = 16.0;
const double _kListSpacing = 8.0;
const double _kHorizontalPadding = 8.0;

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
    
    // ★ 修正: ページネーション適用済みのリストを監視
    final scenariosAsync = ref.watch(displayedScenariosProvider);
    
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
        
        Expanded(
          // ★ 追加: スクロール検知
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // スクロールが最下部に達したらロード
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) { // 少し余裕を持って(-200px)
                notifier.loadMore();
              }
              return false;
            },
            child: _buildBody(context, scenariosAsync, userStatuses),
          ),
        ),
      ],
    );
  }
  
  // _buildFilterChips は変更なし (前回のコードを使用)
  Widget _buildFilterChips(SearchScenariosState state, SearchScenariosViewModel notifier) {
     // ... (省略) ...
     if (state.filter.isInitial) return const SizedBox(height: 8);
     return Padding(
       // ... (前回の実装と同じ)
       padding: const EdgeInsets.symmetric(horizontal: _kHorizontalPadding, vertical: 4.0),
       child: Wrap(
        spacing: 6.0,
        runSpacing: 4.0,
        children: [
          // ... (Chipの実装)
           ActionChip(
            label: const Text('全クリア'),
            onPressed: () => notifier.applyFilter(SearchFilter.initial()),
          )
        ]
       )
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

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _kMobileBreakpoint) {
              final crossAxisCount = (constraints.maxWidth / _kMinCardWidth).floor();
              
              return GridView.builder(
                padding: const EdgeInsets.all(_kGridSpacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                  childAspectRatio: _kGridAspectRatio,
                  crossAxisSpacing: _kGridSpacing,
                  mainAxisSpacing: _kGridSpacing,
                ),
                itemCount: scenarios.length,
                itemBuilder: (context, index) => _buildScenarioItem(scenarios[index], userStatuses),
              );
            } else {
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
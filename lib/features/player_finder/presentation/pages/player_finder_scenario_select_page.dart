import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_page.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_search_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/filter_bottom_sheet.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

class PlayerFinderScenarioSelectPage extends ConsumerStatefulWidget {
  const PlayerFinderScenarioSelectPage({super.key});

  @override
  ConsumerState<PlayerFinderScenarioSelectPage> createState() => _PlayerFinderScenarioSelectPageState();
}

class _PlayerFinderScenarioSelectPageState extends ConsumerState<PlayerFinderScenarioSelectPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final currentSearchTerm = ref.read(playerFinderSearchViewModelProvider).searchTerm;
    _searchController.text = currentSearchTerm;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(playerFinderSearchViewModelProvider);
    final notifier = ref.read(playerFinderSearchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シナリオを選択'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'マイリスト'),
            Tab(text: 'すべて'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'シナリオ名・作者名 (スペースでAND検索)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                notifier.onSearchTermChanged('');
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      notifier.onSearchTermChanged(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
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
                    if (!searchState.filter.isInitial)
                      Container(
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          if (!searchState.filter.isInitial)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  label: const Text('条件クリア'),
                  onPressed: () => notifier.applyFilter(SearchFilter.initial()),
                  avatar: const Icon(Icons.close, size: 16),
                ),
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _MyListTab(),
                _AllScenariosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyListTab extends ConsumerStatefulWidget {
  const _MyListTab();

  @override
  ConsumerState<_MyListTab> createState() => _MyListTabState();
}

class _MyListTabState extends ConsumerState<_MyListTab> {
  bool? _showPossessed = true; 
  bool? _showWantsToGm;
  bool? _showPlayed;
  bool? _showWantsToPlay;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(playerFinderSearchViewModelProvider.notifier);
    final allFilteredScenariosAsync = ref.watch(playerFinderDisplayedScenariosProvider); 
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'すべて', 
                isSelected: _isAllSelected(), 
                onTap: _selectAll,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                  label: '所持', 
                  isSelected: _showPossessed == true, 
                  onTap: () => _toggleFilter('possessed'),
                  selectedColor: Colors.blue.shade700
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                  label: 'GM検討', 
                  isSelected: _showWantsToGm == true, 
                  onTap: () => _toggleFilter('wantsToGm'),
                  selectedColor: Colors.orange.shade700
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                  label: 'PL希望', 
                  isSelected: _showWantsToPlay == true, 
                  onTap: () => _toggleFilter('wantsToPlay'),
                  selectedColor: Colors.pink.shade700
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                  label: '通過済', 
                  isSelected: _showPlayed == true, 
                  onTap: () => _toggleFilter('played'),
                  selectedColor: Colors.green.shade700
              ),
            ],
          ),
        ),

        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                notifier.loadMore();
              }
              return false;
            },
            child: allFilteredScenariosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
              data: (scenarios) {
                final myListScenarios = scenarios.where((s) {
                  final status = userStatuses[s.id];
                  if (status == null) return false;
                  if (status.isUnregistered) return false;

                  if (_isAllSelected()) return true;

                  if (_showPossessed == true && status.isPossessed) return true;
                  if (_showWantsToGm == true && status.wantsToGm) return true;
                  if (_showPlayed == true && status.isPlayed) return true;
                  if (_showWantsToPlay == true && status.wantsToPlay) return true;

                  return false;
                }).toList();

                if (myListScenarios.isEmpty) {
                  return const Center(
                    child: Text(
                      '条件に一致するシナリオがありません。\nチップを切り替えるか、検索条件を変更してください。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: myListScenarios.length,
                  itemBuilder: (context, index) {
                    final scenario = myListScenarios[index];
                    final status = userStatuses[scenario.id]!;
                    
                    return _ClickableScenarioItem(
                      scenario: scenario,
                      status: status,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _isAllSelected() {
    return _showPossessed == null && _showWantsToGm == null && _showPlayed == null && _showWantsToPlay == null;
  }

  void _selectAll() {
    setState(() {
      _showPossessed = null;
      _showWantsToGm = null;
      _showPlayed = null;
      _showWantsToPlay = null;
    });
  }

  void _toggleFilter(String type) {
    setState(() {
      _showPossessed = type == 'possessed';
      _showWantsToGm = type == 'wantsToGm';
      _showPlayed = type == 'played';
      _showWantsToPlay = type == 'wantsToPlay'; // ★ 追加
    });
  }

  Widget _buildFilterChip({
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? Theme.of(context).colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: activeColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      elevation: 0,
      pressElevation: 2,
    );
  }
}

class _AllScenariosTab extends ConsumerWidget {
  const _AllScenariosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerFinderSearchViewModelProvider.notifier);
    final scenariosAsync = ref.watch(playerFinderDisplayedScenariosProvider);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          notifier.loadMore();
        }
        return false;
      },
      child: scenariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (scenarios) {
          if (scenarios.isEmpty) {
            return const Center(child: Text('シナリオが見つかりません。'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              final scenario = scenarios[index];
              final status = userStatuses[scenario.id] ?? const UserScenarioStatus();
              
              return _ClickableScenarioItem(
                scenario: scenario,
                status: status,
              );
            },
          );
        },
      ),
    );
  }
}

class _ClickableScenarioItem extends StatelessWidget {
  final Scenario scenario;
  final UserScenarioStatus status;

  const _ClickableScenarioItem({
    required this.scenario,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ScenarioListItem(
        scenario: scenario,
        status: status,
        isReadOnly: true,
        onStatusChanged: (_) {},
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerFinderPage(scenario: scenario),
            ),
          );
        },
      ),
    );
  }
}
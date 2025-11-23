// ファイルパス: lib/features/player_finder/presentation/pages/player_finder_scenario_select_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_page.dart';

// 検索ロジックは ScenarioLogbook の SearchScenariosViewModel を再利用して効率化
class PlayerFinderScenarioSelectPage extends ConsumerStatefulWidget {
  const PlayerFinderScenarioSelectPage({super.key});

  @override
  ConsumerState<PlayerFinderScenarioSelectPage> createState() => _PlayerFinderScenarioSelectPageState();
}

class _PlayerFinderScenarioSelectPageState extends ConsumerState<PlayerFinderScenarioSelectPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);
    final scenariosAsync = ref.watch(displayedScenariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シナリオを選択'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'フレンズを探したいシナリオを検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: notifier.onSearchTermChanged,
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Stack(
                          children: [
                            ScenarioListItem(
                              scenario: scenario,
                              status: const UserScenarioStatus(),
                              isReadOnly: true, 
                              onStatusChanged: (_) {}, 
                            ),
                            // カード全体をタップ可能にするための透明なレイヤー
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlayerFinderPage(scenario: scenario),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
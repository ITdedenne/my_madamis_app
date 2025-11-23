import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_page.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_search_viewmodel.dart'; // ★新規作成したファイルをインポート
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

// --- Computed Provider: 手持ちシナリオのフィルタリング ---
// (ここは前回と同じでOK。自分のリストはグローバルな状態に依存しても問題ないため)
final myPossessedScenariosProvider = Provider.autoDispose<AsyncValue<List<Scenario>>>((ref) {
  final allScenariosValue = ref.watch(allScenariosProvider);
  final userStatuses = ref.watch(userScenarioStatusProvider);

  return allScenariosValue.whenData((scenarios) {
    return scenarios.where((s) {
      final status = userStatuses[s.id];
      if (status == null) return false;
      return status.isPossessed || status.wantsToGm;
    }).toList();
  });
});

class PlayerFinderScenarioSelectPage extends ConsumerWidget {
  const PlayerFinderScenarioSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('シナリオを選択'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '手持ちから'),
              Tab(text: 'すべて'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyListTab(),
            _AllScenariosTab(),
          ],
        ),
      ),
    );
  }
}

class _MyListTab extends ConsumerWidget {
  const _MyListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myScenariosAsync = ref.watch(myPossessedScenariosProvider);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return myScenariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (myScenarios) {
        if (myScenarios.isEmpty) {
          return const Center(
            child: Text(
              '「所持」または「GM検討中」のシナリオがありません。\nシナリオ手帳で登録してみましょう！',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: myScenarios.length,
          itemBuilder: (context, index) {
            final scenario = myScenarios[index];
            final status = userStatuses[scenario.id] ?? const UserScenarioStatus();
            
            return _ClickableScenarioItem(
              scenario: scenario,
              status: status,
            );
          },
        );
      },
    );
  }
}

class _AllScenariosTab extends ConsumerStatefulWidget {
  const _AllScenariosTab();

  @override
  ConsumerState<_AllScenariosTab> createState() => _AllScenariosTabState();
}

class _AllScenariosTabState extends ConsumerState<_AllScenariosTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★修正: プレイヤーファインダー専用のProviderを使用
    final notifier = ref.read(playerFinderSearchViewModelProvider.notifier);
    final scenariosAsync = ref.watch(playerFinderDisplayedScenariosProvider);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'シナリオ名・作者名 (スペースでAND検索)', // ★ヒント更新
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
                    final status = userStatuses[scenario.id] ?? const UserScenarioStatus();
                    
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
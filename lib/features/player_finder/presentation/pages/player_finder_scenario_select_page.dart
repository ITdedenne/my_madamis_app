// ファイルパス: lib/features/player_finder/presentation/pages/player_finder_scenario_select_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; // allScenariosProvider用
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

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

// --- タブ1: 手持ちのシナリオ (所持 or GM検討中) ---
class _MyListTab extends ConsumerWidget {
  const _MyListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allScenariosAsync = ref.watch(allScenariosProvider);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return allScenariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (allScenarios) {
        // 「所持」または「GM検討中」のシナリオのみを抽出
        final myScenarios = allScenarios.where((s) {
          final status = userStatuses[s.id];
          if (status == null) return false;
          return status.isPossessed || status.wantsToGm;
        }).toList();

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
            // ステータスを取得して渡す
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

// --- タブ2: すべてのシナリオ (検索機能付き) ---
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
    final notifier = ref.read(searchScenariosViewModelProvider.notifier);
    final scenariosAsync = ref.watch(displayedScenariosProvider);
    final userStatuses = ref.watch(userScenarioStatusProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
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
                    // ここでもしっかりステータスを表示する
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

// --- 共通部品: タップ可能なシナリオアイテム ---
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
      child: Stack(
        children: [
          ScenarioListItem(
            scenario: scenario,
            status: status, // ★ 自分のステータスを表示！
            isReadOnly: true, // ここではステータス変更はさせない
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
  }
}
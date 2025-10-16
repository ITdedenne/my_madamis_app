// ファイルパス: lib/features/scenario_logbook/presentation/pages/my_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myListViewModelProvider);
    final notifier = ref.read(myListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイリスト'),
        actions: [
          // TODO: 将来的に並び替え・絞り込み機能を実装する
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '並び替え',
            onPressed: () {
              // 並び替えメニューを表示するロジック
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchMyList(),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyListState state) {
    if (state.isLoading && state.userScenarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(child: Text('エラーが発生しました: ${state.errorMessage}'));
    }

    if (state.userScenarios.isEmpty) {
      return const Center(
        child: Text(
          '記録されたシナリオはありません。\n「探す」タブからシナリオを追加しましょう！',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // `ScenarioListItem` を使うのが理想ですが、ここでは ListTile で代用します
    return ListView.builder(
      itemCount: state.userScenarios.length,
      itemBuilder: (context, index) {
        final userScenario = state.userScenarios[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(userScenario.scenario.title),
            subtitle: Text(userScenario.scenario.authorName),
            trailing: Icon(
              userScenario.status == UserScenarioStatus.played ? Icons.check_circle : Icons.book,
              color: userScenario.status == UserScenarioStatus.played ? Colors.green : Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
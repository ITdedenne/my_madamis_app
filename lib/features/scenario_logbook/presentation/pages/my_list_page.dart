// ファイルパス: lib/features/scenario_logbook/presentation/pages/my_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myListViewModelProvider);
    final notifier = ref.read(myListViewModelProvider.notifier);

    // TabBarView内に配置するため、ScaffoldとAppBarは不要になります。
    // 親の `scenario_logbook_page.dart` がScaffoldを持つためです。
    return RefreshIndicator(
      onRefresh: () => notifier.fetchMyList(),
      child: _buildBody(context, state),
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

    return ListView.builder(
      itemCount: state.userScenarios.length,
      itemBuilder: (context, index) {
        final userScenario = state.userScenarios[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(userScenario.scenario.title),
            subtitle: Text(userScenario.scenario.authorName),
            // trailing に複数のアイコンを表示するためのRowを配置
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userScenario.status.isPlayed)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (userScenario.status.isPlayed && userScenario.status.isPossessed)
                  const SizedBox(width: 8), // アイコン間のスペース
                if (userScenario.status.isPossessed)
                  const Icon(Icons.book, color: Colors.blue),
              ],
            ),
          ),
        );
      },
    );
  }
}
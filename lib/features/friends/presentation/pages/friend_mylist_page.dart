// ファイルパス: lib/features/friends/presentation/pages/friend_mylist_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_user_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';
import 'package:my_madamis_app/models/ModelProvider.dart' hide UserScenario;
import 'package:my_madamis_app/providers.dart';

final otherUserScenariosProvider = FutureProvider.family<List<UserScenario>, String>((ref, userId) async {
  final repo = ref.watch(scenarioRepositoryProvider);
  return GetUserScenariosUseCase(repo).call(userId);
});

class FriendMyListPage extends ConsumerWidget {

  final User targetUser;

  const FriendMyListPage({
    super.key,
    required this.targetUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(otherUserScenariosProvider(targetUser.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('${targetUser.username} のマイリスト'),
      ),
      body: Column(
        children: [
          UserListItem(
            user: targetUser,
            onActionButtonPressed: null,
            actionButtonLabel: null,
          ),
          const Divider(height: 1),
          
          Expanded(
            child: scenariosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('読み込みエラー: $e')),
              data: (scenarios) {
                if (scenarios.isEmpty) {
                  return const Center(child: Text('リストは公開されていません、または登録がありません。'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: scenarios.length,
                  itemBuilder: (context, index) {
                    final item = scenarios[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ScenarioListItem(
                        scenario: item.scenario,
                        status: item.status,
                        onStatusChanged: (_) {},
                        isReadOnly: true, 
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
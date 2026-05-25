// ファイルパス: lib/features/player_finder/presentation/pages/player_finder_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';

class PlayerFinderPage extends ConsumerWidget {
  final Scenario scenario;

  const PlayerFinderPage({super.key, required this.scenario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerFinderProvider(scenario.id));
    final notifier = ref.read(playerFinderProvider(scenario.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('フレンズを探す', style: TextStyle(fontSize: 16)),
            Text(
              scenario.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: _ModeTabButton(
                    label: 'プレイヤーを探す',
                    isSelected: state.mode == PlayerFinderMode.player,
                    onTap: () => notifier.setMode(PlayerFinderMode.player),
                    activeColor: Colors.pink,
                  ),
                ),
                Expanded(
                  child: _ModeTabButton(
                    label: 'GMを探す',
                    isSelected: state.mode == PlayerFinderMode.gm,
                    onTap: () => notifier.setMode(PlayerFinderMode.gm),
                    activeColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: state.users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('エラーが発生しました:\n$error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => notifier.refresh(),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  final emptyMessage = state.mode == PlayerFinderMode.player
                      ? '未通過のフレンズは見つかりませんでした。'
                      : 'GM可能なフレンズは見つかりませんでした。\n(所持・購入検討)';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final searchedUser = users[index];
                    return _buildUserItem(context, searchedUser, state.mode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, SearchedUser searchedUser, PlayerFinderMode mode) {
    String? label;
    Color? color;
    Color? textColor;

    if (mode == PlayerFinderMode.player) {
      // PL検索モード: PL希望者を目立たせる
      if (searchedUser.wantsToPlay) {
        label = '❤️ PL希望！';
        color = Colors.pink.shade50;
        textColor = Colors.pink;
      }
    } else {
      // GM検索モード: 所持 or 購入検討 (通過済は除外されている)
      if (searchedUser.isPossessed) {
        label = '所持';
        color = Colors.blue.shade50;
        textColor = Colors.blue;
      } else if (searchedUser.wantsToGm) {
        label = '購入検討';
        color = Colors.orange.shade50;
        textColor = Colors.orange;
      }
    }

    return UserListItem(
      user: searchedUser.user,
      actionButtonLabel: label,
      actionButtonColor: color,
      actionButtonTextColor: textColor,
      onTap: null, 
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _ModeTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}
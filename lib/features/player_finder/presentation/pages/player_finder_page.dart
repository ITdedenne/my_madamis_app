import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';

class PlayerFinderPage extends ConsumerWidget {
  final Scenario scenario;

  const PlayerFinderPage({super.key, required this.scenario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(playerFinderProvider(scenario.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('未通過フレンズ', style: TextStyle(fontSize: 16)),
            Text(
              scenario.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: asyncState.when(
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
                onPressed: () => ref.read(playerFinderProvider(scenario.id).notifier).refresh(),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
        data: (unplayedFriends) {
          if (unplayedFriends.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '未通過のフレンズは見つかりませんでした。\n全員通過済か、フレンズがいません。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: unplayedFriends.length,
            itemBuilder: (context, index) {
              final searchedUser = unplayedFriends[index];
              final user = searchedUser.user;
              
              // ★ リストアイテムのカスタマイズ (PL希望バッジ)
              return UserListItem(
                user: user,
                // PL希望がある場合はボタンラベルとして表示し、色を変えて目立たせる
                actionButtonLabel: searchedUser.wantsToPlay ? 'PL希望' : null,
                actionButtonColor: searchedUser.wantsToPlay ? Colors.pink.shade50 : null,
                actionButtonTextColor: searchedUser.wantsToPlay ? Colors.pink : null,
                onTap: null, 
              );
            },
          );
        },
      ),
    );
  }
}
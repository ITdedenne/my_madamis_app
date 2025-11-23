// ファイルパス: lib/features/player_finder/presentation/pages/player_finder_page.dart

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
    // ref.watchするだけで取得開始＆状態監視
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
      // .when を使って 3つの状態を宣言的に記述
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
            // FABがなくなったので、bottomの余白は不要
            padding: const EdgeInsets.all(8.0),
            itemCount: unplayedFriends.length,
            itemBuilder: (context, index) {
              final user = unplayedFriends[index];
              return UserListItem(
                user: user,
                actionButtonLabel: null, // 表示専用
                // タップ時の遷移先などが未定の場合は null にしておくとリップルエフェクトが出ず、UXが良い
                onTap: null, 
              );
            },
          );
        },
      ),
    );
  }
}
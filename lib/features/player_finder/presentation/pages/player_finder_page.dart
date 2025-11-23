// ファイルパス: lib/features/player_finder/presentation/pages/player_finder_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard用
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/models/User.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';

class PlayerFinderPage extends ConsumerWidget {
  final Scenario scenario;

  const PlayerFinderPage({super.key, required this.scenario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watchするだけで取得開始＆状態監視 (initState不要)
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
      // データがある場合のみFABを表示
      floatingActionButton: asyncState.whenOrNull(
        data: (friends) => friends.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _copyRecruitmentText(context, friends),
                icon: const Icon(Icons.copy),
                label: const Text('募集文をコピー'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
            : null,
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
          // ListViewの下部にFAB分の余白(padding)を設ける
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 80),
            itemCount: unplayedFriends.length,
            itemBuilder: (context, index) {
              final user = unplayedFriends[index];
              return UserListItem(
                user: user,
                actionButtonLabel: null, // 表示専用
                onTap: () {
                  // プロフィール詳細などへ遷移可能
                },
              );
            },
          );
        },
      ),
    );
  }

  void _copyRecruitmentText(BuildContext context, List<User> friends) {
    final scenarioTitle = scenario.title;
    // "@ユーザー名" のリストを作成
    final mentions = friends.map((u) => '@${u.username}').join(' ');
    
    // 募集テキストを生成
    final text = '''
「$scenarioTitle」の卓を立てようと思っています！
未通過のフレンズ：
$mentions

もしよかったら遊びませんか？
#マダミス #$scenarioTitle
''';

    // クリップボードにコピー
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('募集テキストをコピーしました！SNS等で貼り付けてください。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
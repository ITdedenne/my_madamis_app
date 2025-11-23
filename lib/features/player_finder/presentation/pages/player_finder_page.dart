// ファイルパス: lib/features/player_finder/presentation/pages/player_finder_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';

class PlayerFinderPage extends ConsumerStatefulWidget {
  final Scenario scenario;

  const PlayerFinderPage({super.key, required this.scenario});

  @override
  ConsumerState<PlayerFinderPage> createState() => _PlayerFinderPageState();
}

class _PlayerFinderPageState extends ConsumerState<PlayerFinderPage> {
  @override
  void initState() {
    super.initState();
    // 画面初期化時にデータをロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerFinderViewModelProvider.notifier).loadUnplayedFriends(widget.scenario.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerFinderViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('未通過フレンズ', style: TextStyle(fontSize: 16)),
            Text(
              widget.scenario.title, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(child: Text('エラー: ${state.errorMessage}'));
          }
          if (state.unplayedFriends.isEmpty) {
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
            itemCount: state.unplayedFriends.length,
            itemBuilder: (context, index) {
              final user = state.unplayedFriends[index];
              return UserListItem(
                user: user,
                // 表示専用モード（ボタンなし）
                actionButtonLabel: null, 
                onTap: () {
                  // 必要であれば詳細画面などへ遷移
                },
              );
            },
          );
        },
      ),
    );
  }
}
// ファイルパス: lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/profile_state_notifier.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          // プロフィール編集画面への導線（今回は押しても機能しない）
          IconButton(
            onPressed: () {
              // TODO: ここにマイプロフィール編集画面への遷移処理を実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('編集機能は現在準備中です。')),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Center(
        child: switch (profileState.status) {
          // 読込中
          ProfileStatus.loading => const CircularProgressIndicator(),
          // エラー発生時
          ProfileStatus.error => Text('エラー: ${profileState.errorMessage}'),
          // 正常に読み込めた場合
          ProfileStatus.loaded => RefreshIndicator(
              onRefresh: () => ref.read(profileStateNotifierProvider.notifier).loadCurrentUser(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProfileHeader(context, profileState),
                  const SizedBox(height: 24),
                  _buildSectionTitle('自己紹介'),
                  const SizedBox(height: 8),
                  // 自己紹介文がなければ固定のメッセージを表示
                  Text(
                    profileState.bio ?? '自己紹介が設定されていません。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  //今後似たような機能はデータベース作成後にやるかも？今は一旦おいておく
                  // const SizedBox(height: 24),
                  // _buildSectionTitle('通過シナリオ'),
                  // // TODO: ユーザーが通過したシナリオ一覧をここに表示
                  // const ListTile(
                  //   leading: Icon(Icons.check_circle_outline),
                  //   title: Text('（仮）狂気山脈'),
                  //   subtitle: Text('PL'),
                  // ),
                  // const ListTile(
                  //   leading: Icon(Icons.check_circle_outline),
                  //   title: Text('（仮）何度だって青い月に火を灯した'),
                  //   subtitle: Text('GM'),
                  // )
                ],
              ),
            ),
        },
      ),
    );
  }

  /// プロフィールヘッダー（アイコン、ユーザー名）のUIを構築する
  Widget _buildProfileHeader(BuildContext context, ProfileState state) {
    return Row(
      children: [
        // 固定のアイコン表示
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Icon(
            Icons.person_outline,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        // ユーザー名
        Expanded(
          child: Text(
            state.username ?? 'ユーザー名不明',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 各セクションのタイトルUI
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
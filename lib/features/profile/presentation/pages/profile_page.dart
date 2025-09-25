// ファイルパス: lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import '../notifiers/profile_state_notifier.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileStateNotifierProvider, (previous, next) {
      if (next.updateStatus == UpdateStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('変更に成功しました'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(profileStateNotifierProvider.notifier).resetUpdateStatus();
      }
    });

    final profileState = ref.watch(profileStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: 'プロフィールを編集',
          ),
        ],
      ),
      body: Center(
        child: switch (profileState.status) {
          ProfileStatus.loading => const CircularProgressIndicator(),
          ProfileStatus.error => Text('エラー: ${profileState.errorMessage}'),
          ProfileStatus.loaded => RefreshIndicator(
              onRefresh: () => ref.read(profileStateNotifierProvider.notifier).loadCurrentUser(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProfileHeader(context, profileState),
                  const SizedBox(height: 24),
                  _buildSectionTitle('自己紹介'),
                  const SizedBox(height: 8),
                  Text(
                    profileState.bio != null && profileState.bio!.isNotEmpty
                        ? profileState.bio!
                        : '自己紹介が設定されていません。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('X (Twitter)'),
                  const SizedBox(height: 8),
                  Text(
                    profileState.twitterId != null && profileState.twitterId!.isNotEmpty
                        ? '@${profileState.twitterId!}'
                        : 'X IDが設定されていません。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, ProfileState state) {
    // ... (変更なし) ...
        return Row(
      children: [
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
        Expanded(
          child: Text(
            state.username ?? 'ユーザー名未設定', // 未設定の場合の表示
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    // ... (変更なし) ...
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
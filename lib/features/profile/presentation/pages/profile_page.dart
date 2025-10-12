// ファイルパス: lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            onPressed: profileState.profile != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          initialProfile: profileState.profile!,
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.edit),
            tooltip: 'プロフィールを編集',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileViewModelProvider.notifier).loadUserProfile(),
        child: Center(
          child: switch (profileState.status) {
            ProfileStatus.loading => const CircularProgressIndicator(),
            ProfileStatus.error => Text('エラー: ${profileState.errorMessage}'),
            ProfileStatus.loaded => ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProfileHeader(context, profileState.profile!.username),
                  const SizedBox(height: 24),
                  _buildSectionTitle('自己紹介'),
                  const SizedBox(height: 8),
                  Text(
                    profileState.profile!.bio.isNotEmpty
                        ? profileState.profile!.bio
                        : '自己紹介が設定されていません。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('X (Twitter)'),
                  const SizedBox(height: 8),
                  Text(
                    profileState.profile!.twitterId.isNotEmpty
                        ? '@${profileState.profile!.twitterId}'
                        : 'X IDが設定されていません。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ProfileStatus.initial => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String username) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person, size: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            username,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
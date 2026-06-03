// ファイルパス: lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:flutter/services.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        centerTitle: true,
        elevation: 0,
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
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'プロフィールを編集',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(profileViewModelProvider.notifier).loadUserProfile(),
        child: Center(
          child: switch (profileState.status) {
            ProfileStatus.loading => const CircularProgressIndicator(),
            ProfileStatus.error => Text('エラー: ${profileState.errorMessage}'),
            ProfileStatus.loaded => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                children: [
                  _buildProfileHeader(context, profileState.profile!.username),
                  const SizedBox(height: 32),

                  // フレンドID (publicUserId が null でない場合のみ表示)
                  if (profileState.profile!.publicUserId != null) ...[
                    _buildInfoCard(
                      context: context,
                      title: 'フレンドID',
                      icon: Icons.badge_outlined,
                      content: _buildFriendId(
                        context,
                        profileState.profile!.publicUserId!,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildInfoCard(
                    context: context,
                    title: '自己紹介',
                    icon: Icons.person_outline,
                    content: Text(
                      profileState.profile!.bio.isNotEmpty
                          ? profileState.profile!.bio
                          : '自己紹介が設定されていません。',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: profileState.profile!.bio.isNotEmpty
                                ? Colors.black87
                                : Colors.black54,
                          ),
                    ),
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
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          username,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            content,
          ],
        ),
      ),
    );
  }

  /// フレンドID表示用のウィジェット
  Widget _buildFriendId(BuildContext context, String friendId) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: friendId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('フレンドIDをコピーしました'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                friendId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.copy_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
// ファイルパス: lib/features/friends/presentation/pages/friends_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friend_mylist_page.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';

class FriendsListPage extends ConsumerWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsViewModelProvider);
    final notifier = ref.read(friendsViewModelProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.followingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'まだフレンズがいません。\n「探す」タブからユーザーを検索して\n追加しましょう！',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadFollowingUsers(),
      child: ListView.builder(
        // リストが少ない時でもスクロール可能にしてRefreshIndicatorを機能させる
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        itemCount: state.followingUsers.length,
        itemBuilder: (context, index) {
          final user = state.followingUsers[index];
          return Card(
            elevation: 0, // フラットなデザイン
            color: Theme.of(context).colorScheme.surfaceContainer, // 背景色を微調整
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${user.publicUserId}'),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_outlined, color: Colors.grey),
                tooltip: 'フォロー解除',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('フォロー解除'),
                      content: Text('${user.username}さんのフォローを解除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            notifier.unfollowUser(user.id);
                            Navigator.pop(context);
                          },
                          child: const Text('解除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendMyListPage(
                      targetUserId: user.id,
                      targetUsername: user.username,
                      targetBio: user.bio ?? '',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
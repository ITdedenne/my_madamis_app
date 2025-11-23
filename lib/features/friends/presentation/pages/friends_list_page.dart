// ファイルパス: lib/features/friends/presentation/pages/friends_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friend_mylist_page.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';

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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
        itemCount: state.followingUsers.length,
        itemBuilder: (context, index) {
          final user = state.followingUsers[index];
          
          return UserListItem(
            user: user,
            isFollowing: true, // 一覧にいる＝フォロー中
            actionButtonLabel: '解除',
            actionButtonColor: Colors.transparent, // 背景なし（Outlined風）
            actionButtonTextColor: Colors.grey,
            
            onActionButtonPressed: () {
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendMyListPage(targetUser: user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
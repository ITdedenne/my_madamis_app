// ファイルパス: lib/features/friends/presentation/pages/friends_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/user_search_page.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friend_mylist_page.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsViewModelProvider);
    final notifier = ref.read(friendsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンズ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'ユーザー検索',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchPage()),
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.followingUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'まだフレンズがいません。\n右上のアイコンから検索して追加しましょう！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => notifier.loadFollowingUsers(),
                  child: ListView.builder(
                    itemCount: state.followingUsers.length,
                    itemBuilder: (context, index) {
                      final user = state.followingUsers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user.username),
                        subtitle: Text('ID: ${user.publicUserId}'),
                        trailing: OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('フォロー解除'),
                                content: Text('${user.username}さんのフォローを解除しますか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context), 
                                    child: const Text('キャンセル')
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
                          child: const Text('解除'),
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
                      );
                    },
                  ),
                ),
    );
  }
}
// ファイルパス: lib/features/friends/presentation/pages/friends_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friend_mylist_page.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';
import 'package:my_madamis_app/models/ModelProvider.dart'; // User型

class FriendsListPage extends ConsumerStatefulWidget {
  const FriendsListPage({super.key});

  @override
  ConsumerState<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends ConsumerState<FriendsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchText.isEmpty) return users;
    return users.where((u) {
      return u.username.toLowerCase().contains(_searchText) ||
             u.publicUserId.contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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

    final filteredUsers = _filterUsers(state.followingUsers);

    return Column(
      children: [
        // ★ クライアントサイド検索バー (v2.15)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'フレンズ内を検索 (名前/ID)',
              prefixIcon: const Icon(Icons.filter_list),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadFollowingUsers(),
            child: filteredUsers.isEmpty
                ? const Center(child: Text('該当するフレンズはいません'))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      
                      return UserListItem(
                        user: user,
                        isFollowing: true, 
                        actionButtonLabel: '解除',
                        actionButtonColor: Colors.transparent, 
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
          ),
        ),
      ],
    );
  }
}
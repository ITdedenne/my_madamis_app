// ファイルパス: lib/features/friends/presentation/pages/user_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/user_search_viewmodel.dart';
import 'package:my_madamis_app/common/widgets/user_list_item.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friend_mylist_page.dart';

class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({super.key});

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchViewModelProvider);
    final searchNotifier = ref.read(userSearchViewModelProvider.notifier);
    
    final friendsState = ref.watch(friendsViewModelProvider);
    final friendsNotifier = ref.read(friendsViewModelProvider.notifier);

    ref.listen<UserSearchState>(userSearchViewModelProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
        searchNotifier.clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        searchNotifier.clearMessages();
      }
    });

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ユーザー名で検索', // 内部的にID検索可能でもUIに表示しないなら変更を推奨
                prefixIcon: const Icon(Icons.search),
                filled: true,
                // ignore: deprecated_member_use
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => searchNotifier.search(_searchController.text),
                ),
              ),
              onSubmitted: (value) => searchNotifier.search(value),
            ),
          ),
        ),

        if (searchState.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (searchState.searchResults.isEmpty && _searchController.text.isNotEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('ユーザーが見つかりません', style: TextStyle(color: Colors.grey))),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = searchState.searchResults[index];
                final isFollowing = friendsState.followingUsers.any((u) => u.id == user.id);
                // 個別にローディング状態を判定
                final isThisUserProcessing = searchState.processingUserId == user.id;

                return UserListItem(
                  user: user,
                  isFollowing: isFollowing,
                  isProcessing: isThisUserProcessing,
                  actionButtonLabel: isFollowing ? 'フォロー済' : 'フォロー',
                  actionButtonColor: isFollowing ? Colors.grey[300] : null, 
                  actionButtonTextColor: isFollowing ? Colors.black54 : null,
                  
                  onActionButtonPressed: () {
                    if (isFollowing) {
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
                                friendsNotifier.unfollowUser(user.id);
                                Navigator.pop(context);
                              },
                              child: const Text('解除', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      searchNotifier.followUser(user);
                    }
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
              childCount: searchState.searchResults.length,
            ),
          ),
      ],
    );
  }
}
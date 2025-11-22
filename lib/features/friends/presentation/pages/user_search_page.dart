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
    // 検索結果の状態
    final searchState = ref.watch(userSearchViewModelProvider);
    final searchNotifier = ref.read(userSearchViewModelProvider.notifier);
    
    // フォロー状況を確認するためにフレンズ一覧の状態も監視
    final friendsState = ref.watch(friendsViewModelProvider);
    final friendsNotifier = ref.read(friendsViewModelProvider.notifier);

    // スナックバー制御
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
      // ★ 重要: スクロール時に自動的にキーボードを閉じる
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // 検索バーをSliverとして配置 (スクロールに合わせて隠れるような挙動も可能)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ユーザー名またはID(7桁)で検索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
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

        // 検索結果エリア
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
                // 既にフォローしているか判定
                final isFollowing = friendsState.followingUsers.any((u) => u.id == user.id);

                return UserListItem(
                  user: user,
                  isFollowing: isFollowing,
                  isProcessing: searchState.isProcessing,
                  actionButtonLabel: isFollowing ? 'フォロー済' : 'フォロー',
                  // フォロー済みの場合は薄くして「完了感」を出す
                  actionButtonColor: isFollowing ? Colors.grey[300] : null, 
                  actionButtonTextColor: isFollowing ? Colors.black54 : null,
                  
                  onActionButtonPressed: () {
                    if (isFollowing) {
                      // フォロー解除確認ダイアログ
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
                      // フォロー実行
                      searchNotifier.followUser(user);
                    }
                  },
                  onTap: () {
                    // 詳細画面（他人のマイリスト）へ遷移
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
// ファイルパス: lib/features/friends/presentation/pages/user_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/user_search_viewmodel.dart';

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
    
    // ★ 追加: フォロー状況を確認するためにフレンズ一覧の状態も監視する
    final friendsState = ref.watch(friendsViewModelProvider);
    final friendsNotifier = ref.read(friendsViewModelProvider.notifier);

    // 検索用スナックバー制御 (フォロー成功/エラー)
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

    // ★ 追加: フレンズ用スナックバー制御 (解除成功/エラー)
    ref.listen<FriendsState>(friendsViewModelProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
        friendsNotifier.clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        friendsNotifier.clearMessages();
      }
    });

    return Column(
      children: [
        // 検索バーエリア
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ユーザー名またはID(7桁)で検索',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.zero,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => searchNotifier.search(_searchController.text),
              ),
            ),
            onSubmitted: (value) => searchNotifier.search(value),
          ),
        ),

        // 検索結果エリア
        Expanded(
          child: searchState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : searchState.searchResults.isEmpty && _searchController.text.isNotEmpty && !searchState.isLoading
                  ? const Center(child: Text('ユーザーが見つかりません'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: searchState.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchState.searchResults[index];
                        
                        // ★ 追加: 既にフォローしているか判定
                        final isFollowing = friendsState.followingUsers.any((u) => u.id == user.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(child: Icon(Icons.person)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.username,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'ID: ${user.publicUserId}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // ★ 修正: ボタンの出し分け
                                    ElevatedButton(
                                      onPressed: searchState.isProcessing
                                          ? null
                                          : () {
                                              if (isFollowing) {
                                                // ★ フォロー解除ダイアログを表示
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
                                                // ★ フォロー実行
                                                searchNotifier.followUser(user);
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        // フォロー済みの場合は色を変える（オプション）
                                        backgroundColor: isFollowing ? Colors.grey[300] : null,
                                        foregroundColor: isFollowing ? Colors.black87 : null,
                                      ),
                                      child: Text(isFollowing ? 'フォロー済' : 'フォロー'),
                                    ),
                                  ],
                                ),
                                if (user.bio != null && user.bio!.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(),
                                  ),
                                  Text(
                                    user.bio!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
// ファイルパス: lib/features/friends/presentation/pages/user_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final state = ref.watch(userSearchViewModelProvider);
    final notifier = ref.read(userSearchViewModelProvider.notifier);

    ref.listen<UserSearchState>(userSearchViewModelProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
        notifier.clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        notifier.clearMessages();
      }
    });

    // Scaffoldを削除し、Columnで構成する
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
              contentPadding: EdgeInsets.zero, // 高さを少し抑える
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => notifier.search(_searchController.text),
              ),
            ),
            onSubmitted: (value) => notifier.search(value),
          ),
        ),

        // 検索結果エリア
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.searchResults.isEmpty && _searchController.text.isNotEmpty && !state.isLoading
                  // 検索したが結果が0件の場合の表示（オプション）
                  ? const Center(child: Text('ユーザーが見つかりません'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = state.searchResults[index];
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
                                    ElevatedButton(
                                      onPressed: state.isProcessing
                                          ? null
                                          : () => notifier.followUser(user),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text('フォロー'),
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
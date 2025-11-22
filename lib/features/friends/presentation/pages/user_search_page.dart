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

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'ユーザー名またはID(7桁)で検索',
            border: InputBorder.none,
          ),
          onSubmitted: (value) => notifier.search(value),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => notifier.search(_searchController.text),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.searchResults.length,
              itemBuilder: (context, index) {
                final user = state.searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                              child: const Text('フォロー'),
                            ),
                          ],
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const Divider(height: 16),
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
    );
  }
}
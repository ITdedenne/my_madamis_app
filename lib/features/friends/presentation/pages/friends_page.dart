// ファイルパス: lib/features/friends/presentation/pages/friends_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friends_list_page.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/user_search_page.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('フレンズ'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.person_search),
                text: '探す',
              ),
              Tab(
                icon: Icon(Icons.people),
                text: '一覧',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserSearchPage(),  // 0番目のタブ: 検索
            FriendsListPage(), // 1番目のタブ: 一覧
          ],
        ),
      ),
    );
  }
}
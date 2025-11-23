// ファイルパス: lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/settings_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friends_page.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_scenario_select_page.dart';
import 'package:my_madamis_app/features/group_search/presentation/pages/group_search_settings_page.dart'; 

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
      if (next.flashMessage != null && next.status == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.flashMessage!)),
          );
          ref.read(authStateNotifierProvider.notifier).clearFlashMessage();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'プロフィール',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'サインアウト',
            onPressed: () {
              ref.read(authStateNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ようこそ、${authState.username ?? ''}さん！',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // --- シナリオ手帳カード ---
            Card(
              elevation: 2,
              color: Colors.blue.shade50,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScenarioLogbookPage()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book, size: 40, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text('シナリオ手帳', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text(
                        '通過したシナリオや所持しているシナリオを記録・管理できます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // --- フレンズ機能カード ---
            Card(
              elevation: 2,
              color: Colors.orange.shade50,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsPage()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.people, size: 40, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text('フレンズ', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text(
                        'ユーザー検索やフォローリストの管理、マイリストの共有ができます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- プレイヤーファインダーカード ---
            Card(
              elevation: 2,
              color: Colors.purple.shade50,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerFinderScenarioSelectPage()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.person_search, size: 40, color: Colors.purple),
                      const SizedBox(height: 8),
                      Text('プレイヤーを探す', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text(
                        '遊びたいシナリオを指定して、未通過のフレンズを検索できます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- ★ 追加: シナリオグループ検索カード ---
            Card(
              elevation: 2,
              color: Colors.teal.shade50,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroupSearchSettingsPage()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.groups, size: 40, color: Colors.teal),
                      const SizedBox(height: 8),
                      Text('グループ検索', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text(
                        '集まったメンバー全員が遊べる（未通過の）シナリオを一括検索します。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
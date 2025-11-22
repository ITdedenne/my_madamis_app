// ファイルパス: lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/settings_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart';
// ★ 追加: フレンズページへのインポート
import 'package:my_madamis_app/features/friends/presentation/pages/friends_page.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ようこそ、${authState.username ?? ''}さん！',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // --- シナリオ手帳カード ---
              Card(
                elevation: 4,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book, size: 48, color: Colors.blueAccent),
                        const SizedBox(height: 12),
                        Text('シナリオ手帳', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
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
              
              const SizedBox(height: 20), // カード間の余白

              // --- ★ 追加: フレンズ機能カード ---
              Card(
                elevation: 4,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people, size: 48, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text('フレンズ', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
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

              const Spacer(), // 下部に余白を持たせる
            ],
          ),
        ),
      ),
    );
  }
}
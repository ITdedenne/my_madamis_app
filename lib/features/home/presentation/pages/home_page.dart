// ファイルパス: lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
// ▼▼▼ 以下2行を追加しました ▼▼▼
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/settings_page.dart';

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
          // メッセージを表示したらクリアする
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
          child: Text(
            'ようこそ！${authState.username ?? ''}さん！\nログインに成功しました。',
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
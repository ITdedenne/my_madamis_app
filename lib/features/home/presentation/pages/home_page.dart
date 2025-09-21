// ファイルパス: lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ▼▼▼ 1. import文を追加 ▼▼▼
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import '../../../auth/presentation/notifiers/auth_state_notifier.dart';
import '../../../auth/presentation/pages/login_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          // --- ▼▼▼ 2. IconButtonを追加 ▼▼▼ ---
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'プロフィール', // アイコン長押しで表示されるテキスト
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          // --- ▲▲▲ IconButtonの追加ここまで ▲▲▲ ---
          // サインアウトボタン
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'サインアウト',
            onPressed: () {
              ref.read(authStateNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'ようこそ！ログインに成功しました。',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
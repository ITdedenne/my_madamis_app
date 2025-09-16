// ファイルパス: lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/auth_state_notifier.dart';
import 'login_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 認証状態を監視して、サインアウトされたらログイン画面に戻る
    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false, // すべての履歴を削除
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          // サインアウトボタン
          IconButton(
            icon: const Icon(Icons.logout),
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
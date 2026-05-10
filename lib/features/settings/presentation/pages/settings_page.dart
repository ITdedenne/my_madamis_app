import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';

// ★ 変更点: LoginViewModel ではなく AuthStateNotifier をインポートします
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';

import 'package:my_madamis_app/features/settings/presentation/pages/update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_password_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          
          // メールアドレス変更
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('メールアドレス変更'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateEmailPage()),
              );
            },
          ),
          const Divider(height: 1),
          
          // パスワード変更
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('パスワード変更'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
              );
            },
          ),
          const Divider(height: 1),

          const SizedBox(height: 32),

          // ログアウトボタン
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'ログアウト',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              // 1. 確認ダイアログを表示
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしてログイン画面に戻りますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'ログアウト',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              // キャンセルされた場合は何もしない
              if (confirm != true) return;

              // 2. ログアウト処理を実行
              // ★ 変更点: authStateNotifierProvider の signOut を呼び出します
              await ref.read(authStateNotifierProvider.notifier).signOut();

              // 3. ログイン画面へ遷移（これまでの画面スタックをすべて削除）
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
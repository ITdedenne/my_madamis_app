// ファイルパス: lib/features/settings/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_password_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('メールアドレス変更'),
            subtitle: const Text('サインインに使用するメールアドレスを変更します'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateEmailPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('パスワード変更'),
            subtitle: const Text('サインインに使用するパスワードを変更します'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
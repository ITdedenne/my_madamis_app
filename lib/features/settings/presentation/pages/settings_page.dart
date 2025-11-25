// ファイルパス: lib/features/settings/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_password_page.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/delete_user_account_viewmodel.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(deleteAccountViewModelProvider);
    final deleteNotifier = ref.read(deleteAccountViewModelProvider.notifier);

    // 退会処理完了の監視
    ref.listen<DeleteAccountState>(deleteAccountViewModelProvider, (prev, next) {
      if (next.status == DeleteAccountStatus.success) {
        // ログイン画面へ強制遷移（履歴全削除）
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('退会処理が完了しました。ご利用ありがとうございました。')),
        );
      } else if (next.status == DeleteAccountStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '不明なエラー')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('メールアドレス変更'),
                subtitle: const Text('サインインに使用するメールアドレスを変更します'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
                  );
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 40),
              
              // 退会ボタン
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('退会する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: const Text('アカウントとすべてのデータを削除します'),
                onTap: () => _showDeleteConfirmationDialog(context, deleteNotifier),
              ),
            ],
          ),
          
          // ローディングオーバーレイ
          if (deleteState.status == DeleteAccountStatus.loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, DeleteAccountViewModel notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('本当に退会しますか？'),
        content: const Text(
          '退会すると、シナリオの通過記録やフレンズ情報など、すべてのアカウントデータが完全に削除されます。\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              notifier.deleteAccount(); // 処理実行
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退会してデータを削除'),
          ),
        ],
      ),
    );
  }
}
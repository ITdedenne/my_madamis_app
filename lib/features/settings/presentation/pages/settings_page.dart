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
                onTap: () => showDialog(
                  context: context,
                  // ダイアログ専用のContextを使用
                  builder: (dialogContext) => _DeleteConfirmationDialog(
                    onConfirm: () {
                       Navigator.pop(dialogContext); // ダイアログを閉じる
                       deleteNotifier.deleteAccount(); // 処理実行
                    },
                  ),
                ),
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
}

// 安全装置付きの削除確認ダイアログ
class _DeleteConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({required this.onConfirm});

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  bool _isConfirmed = false; // トグルスイッチの状態

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('本当に退会しますか？', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '退会すると、以下のデータがすべて完全に削除されます。\nこの操作は取り消せません。',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('・シナリオの通過記録'),
                Text('・所持/購入検討リスト'),
                Text('・フォロー/フォロワー情報'),
                Text('・プロフィール情報'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 同意トグルスイッチ（安全装置）
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: SwitchListTile(
              title: const Text(
                '上記を理解し、退会します',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              value: _isConfirmed,
              onChanged: (value) {
                setState(() {
                  _isConfirmed = value;
                });
              },
              activeColor: Colors.red,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        // トーンアップするボタン
        FilledButton(
          onPressed: _isConfirmed
              ? widget.onConfirm
              : null, // スイッチがOFFなら押せない（無効化）
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withOpacity(0.2), // 無効時は薄い赤
          ),
          child: const Text('退会実行'),
        ),
      ],
    );
  }
}
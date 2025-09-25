// lib/features/settings/presentation/pages/confirm_update_email_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';

class ConfirmUpdateEmailPage extends ConsumerStatefulWidget {
  final String newEmail;
  const ConfirmUpdateEmailPage({super.key, required this.newEmail});

  @override
  ConsumerState<ConfirmUpdateEmailPage> createState() =>
      _ConfirmUpdateEmailPageState();
}

class _ConfirmUpdateEmailPageState
    extends ConsumerState<ConfirmUpdateEmailPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.emailUpdateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メールアドレスが正常に変更されました。'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        // 設定画面まで戻る (2画面分)
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: ${next.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('確認コード入力')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.newEmail} に送信された確認コードを入力してください。'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                  labelText: '確認コード', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authState.status == AuthStatus.loading
                  ? null
                  : () => ref
                      .read(authStateNotifierProvider.notifier)
                      .confirmUpdateEmail(_codeController.text),
              child: authState.status == AuthStatus.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('変更を確定'),
            ),
          ],
        ),
      ),
    );
  }
}
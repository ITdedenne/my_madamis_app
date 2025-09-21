// ファイルパス: lib/pages/reset_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/auth_state_notifier.dart';

class ResetPasswordPage extends ConsumerWidget {
  final String username;
  const ResetPasswordPage({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final confirmationCodeController = TextEditingController();
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.passwordResetSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスワードが正常にリセットされました。ログインしてください。')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワードを再設定')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: '新しいパスワード')),
            TextFormField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: '新しいパスワードを再入力')),
            TextFormField(controller: confirmationCodeController, decoration: const InputDecoration(labelText: '認証コード')),
            const SizedBox(height: 20),
            if (authState.status == AuthStatus.loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () {
                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスワードが一致しません')));
                    return;
                  }
                  ref.read(authStateNotifierProvider.notifier).confirmResetPassword(
                        username: username,
                        newPassword: newPasswordController.text,
                        confirmationCode: confirmationCodeController.text,
                      );
                },
                child: const Text('パスワードを更新'),
              ),
            if (authState.status == AuthStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('エラー: ${authState.errorMessage}', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
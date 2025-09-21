// ファイルパス: lib/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/pages/reset_password_page.dart';
import '../notifiers/auth_state_notifier.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.passwordResetRequired) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordPage(username: emailController.text)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワードをリセット')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            const SizedBox(height: 20),
            if (authState.status == AuthStatus.loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () => ref.read(authStateNotifierProvider.notifier).resetPassword(emailController.text),
                child: const Text('送信'),
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
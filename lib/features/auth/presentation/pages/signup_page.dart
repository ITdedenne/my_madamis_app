// ファイルパス: lib/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/auth_state_notifier.dart';
import 'confirmation_page.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.confirmationRequired) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ConfirmationPage(username: next.usernameForConfirmation!),
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー登録')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: 'ユーザー名')),
            TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'メールアドレス')),
            TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'パスワード')),
            const SizedBox(height: 20),
             if (authState.status == AuthStatus.loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () => ref.read(authStateNotifierProvider.notifier).signUp(
                      usernameController.text,
                      passwordController.text,
                      emailController.text,
                    ),
                child: const Text('登録'),
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
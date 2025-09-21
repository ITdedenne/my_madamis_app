// ファイルパス: lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';
import '../notifiers/auth_state_notifier.dart';
import 'forgot_password_page.dart'; // 追加
import 'signup_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          // ... (変更なし) ...
          children: [
            TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'メールアドレス')),
            const SizedBox(height: 12),
            TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'パスワード')),
            const SizedBox(height: 20),
            if (authState.status == AuthStatus.loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () => ref.read(authStateNotifierProvider.notifier).signIn(emailController.text, passwordController.text),
                child: const Text('ログイン'),
              ),
            if (authState.status == AuthStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('エラー: ${authState.errorMessage}', style: const TextStyle(color: Colors.red)),
              ),
            TextButton(
              // onPressedのコメントアウトを解除し、ナビゲーションを追加
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
              },
              child: const Text('パスワードを忘れた場合はこちら'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
              child: const Text('新規登録'),
            ),
          ],
        ),
      ),
    );
  }
}
// ファイルパス: lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/pages/home_page.dart';
import '../notifiers/auth_state_notifier.dart';
import 'signup_page.dart';
// import 'home_page.dart'; // TODO: ログイン後のホーム画面を作成
// import 'forgot_password_page.dart'; // TODO: パスワードリセット画面を作成

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        // ログイン成功時の画面遷移
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              onPressed: () { /* Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())); */ },
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
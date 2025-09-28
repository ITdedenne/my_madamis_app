// ファイルパス: lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/signup_page.dart';
// ▼▼▼ この行がエラーを解決します ▼▼▼
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controllerはbuildメソッド内で定義するのが安全です
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    final loginState = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);

    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      if (next.errorMessage != null) {
        // build完了前にSnackBarを出すとエラーになるため、遅延実行する
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
      // 認証が成功したら、グローバルな認証状態を更新します
      // 画面遷移はmain.dartのMyAppウィジェットが自動的に行います
      if (next.isAuthenticated) {
        ref.read(authStateNotifierProvider.notifier).setAuthenticated(next.username!);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CustomTextFormField(
              controller: emailController,
              labelText: 'メールアドレス',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: passwordController,
              labelText: 'パスワード',
              obscureText: true,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'ログイン',
              isLoading: loginState.isLoading,
              onPressed: () {
                // フォーカスを外してキーボードを閉じる
                FocusScope.of(context).unfocus(); 
                notifier.signIn(
                  emailController.text,
                  passwordController.text,
                );
              },
            ),
            TextButton(
              onPressed: () {
                // TODO: パスワードリセット画面へ
              },
              child: const Text('パスワードを忘れた場合はこちら'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpPage()),
              ),
              child: const Text('新規登録'),
            ),
          ],
        ),
      ),
    );
  }
}
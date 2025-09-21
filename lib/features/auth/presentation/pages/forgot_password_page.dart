// ファイルパス: lib/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/reset_password_page.dart';
import '../notifiers/auth_state_notifier.dart';

// ConsumerWidget から ConsumerStatefulWidget に変更
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  // TextEditingControllerをbuildメソッドの外に移動
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // initStateで一度だけ初期化する
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    // ウィジェットが不要になったらcontrollerを破棄する
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.passwordResetRequired) {
        // 状態を保持している_emailControllerからテキストを取得
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ResetPasswordPage(username: _emailController.text)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワードをリセット')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              // controllerを_emailControllerに変更
              controller: _emailController,
              decoration: const InputDecoration(labelText: '登録したメールアドレス'),
            ),
            const SizedBox(height: 20),
            if (authState.status == AuthStatus.loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () => ref
                    .read(authStateNotifierProvider.notifier)
                    // controllerを_emailControllerに変更
                    .resetPassword(_emailController.text),
                child: const Text('リセットコードを送信'),
              ),
            if (authState.status == AuthStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('エラー: ${authState.errorMessage}',
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
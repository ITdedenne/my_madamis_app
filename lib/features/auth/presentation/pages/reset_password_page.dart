// ファイルパス: lib/features/auth/presentation/pages/reset_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String username;
  const ResetPasswordPage({required this.username, super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    
    // パスワードリセットが成功したらログイン画面に戻る
    ref.listen(authStateNotifierProvider, (_, next) {
      // AuthNotifier内で unauthenticated に遷移したら
      if (next.status == AuthStatus.unauthenticated) { // ★修正: unauthenticated に変更
        // ログイン画面へ戻り、それまでの画面履歴をクリア
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
        // 成功メッセージ表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードを正常にリセットしました。新しいパスワードでサインインしてください。')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワードを再設定')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '${widget.username}宛に送信されたリセットコードと、新しいパスワードを入力してください。',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'リセットコード'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: '新しいパスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (authState.status == AuthStatus.loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () {
                  ref.read(authStateNotifierProvider.notifier).confirmPasswordReset(
                    widget.username,
                    _newPasswordController.text,
                    _codeController.text,
                  );
                },
                child: const Text('パスワードを再設定'),
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
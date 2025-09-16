// ファイルパス: lib/pages/confirmation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/auth_state_notifier.dart';

class ConfirmationPage extends ConsumerWidget {
  final String username;
  const ConfirmationPage({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    
    ref.listen(authStateNotifierProvider, (_, next) {
        if (next.status == AuthStatus.unauthenticated && next.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
            Navigator.of(context).popUntil((route) => route.isFirst);
        }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('コード認証')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('$username で登録したメールアドレスに届いたコードを入力してください。'),
            TextFormField(controller: codeController, decoration: const InputDecoration(labelText: '認証コード')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(authStateNotifierProvider.notifier).confirmSignUp(username, codeController.text),
              child: const Text('認証'),
            ),
          ],
        ),
      ),
    );
  }
}
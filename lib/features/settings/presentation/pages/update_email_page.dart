// lib/features/settings/presentation/pages/update_email_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/confirm_update_email_page.dart';

class UpdateEmailPage extends ConsumerStatefulWidget {
  const UpdateEmailPage({super.key});

  @override
  ConsumerState<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends ConsumerState<UpdateEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateNotifierProvider.notifier)
          .updateEmail(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.confirmationRequiredForUpdate) {
        // 状態がリセットされるように、notifierの状態を一度リセット
        ref.read(authStateNotifierProvider.notifier).resetStatus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ConfirmUpdateEmailPage(newEmail: _emailController.text),
          ),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('エラー: ${next.errorMessage}'),
              backgroundColor: Colors.red),
        );
      }
    });

    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('メールアドレス変更')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: '新しいメールアドレス', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
                    return '有効なメールアドレスを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _submit,
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('確認コードを送信'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
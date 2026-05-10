import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/reset_password_page.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);

    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.passwordResetRequired) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(username: _emailController.text),
          ),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワードをリセット')),
      body: Center( // PC対応：中央寄せ
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500), // PC対応：横幅制限
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '登録しているメールアドレスを入力してください。\nパスワード再設定用のリセットコードを送信します。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: '登録したメールアドレス',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'メールアドレスを入力してください' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'リセットコードを送信',
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ref.read(authStateNotifierProvider.notifier).resetPassword(
                              _emailController.text,
                            );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
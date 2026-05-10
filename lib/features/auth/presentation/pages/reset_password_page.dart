import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String username; // エラーにならないようusernameで受け取る
  const ResetPasswordPage({required this.username, super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  
  // パスワード表示切替のフラグ
  bool _isObscure = true;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    
    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードを正常にリセットしました。新しいパスワードでログインしてください。')),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワードを再設定')),
      body: Center( // PC対応：中央寄せ
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500), // PC対応：横幅制限
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.username} 宛に送信されたリセットコードと、新しいパスワードを入力してください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomTextFormField(
                    controller: _codeController,
                    labelText: 'リセットコード',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'コードを入力してください' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _newPasswordController,
                    labelText: '新しいパスワード',
                    obscureText: _isObscure,
                    // 右端の目玉アイコン
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                    validator: (v) => (v == null || v.length < 8) ? '8文字以上で入力してください' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'パスワードを再設定',
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ref.read(authStateNotifierProvider.notifier).confirmPasswordReset(
                          widget.username,
                          _newPasswordController.text,
                          _codeController.text,
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
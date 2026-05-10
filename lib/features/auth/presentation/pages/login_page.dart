import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/signup_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // パスワードの伏せ字状態管理
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);

    // ★修正: LoginState に定義されているプロパティ（errorMessage等）を使用する
    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      // エラーメッセージが存在する場合のみSnackBarを表示する
      // (もし LoginState のプロパティ名が `error` など別の名前であれば、そこだけ合わせてください)
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Center( 
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500), 
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'マイマダミス',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'メールアドレス',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'メールアドレスを入力してください' : null,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  CustomTextFormField(
                    controller: _passwordController,
                    labelText: 'パスワード',
                    obscureText: _isObscure, 
                    suffixIcon: IconButton( 
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'パスワードを入力してください' : null,
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      ),
                      child: const Text('パスワードを忘れた場合'),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  PrimaryButton(
                    text: 'ログイン',
                    // ★修正: LoginStatus ではなく LoginState の isLoading プロパティを使用
                    isLoading: viewModel.isLoading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ref.read(loginViewModelProvider.notifier).signIn(
                          _emailController.text,
                          _passwordController.text,
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 48), 
                  
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('はじめての方', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blue),
                    ),
                    child: const Text(
                      '新規アカウント作成',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
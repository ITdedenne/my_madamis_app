// ファイルパス: lib/features/auth/presentation/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; 

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ★修正: asyncを追加し、サインアウト処理を実行
  void _goToNextStep() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (Amplify.isConfigured) {
           await Amplify.Auth.signOut();
        }
      } catch (e) {
        safePrint('既存セッションのサインアウトに失敗しました: $e');
        // エラーが発生しても処理は続行（セッションがない可能性が高いため）
      }

      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProfilePage(email: _emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録 (1/2)')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('まず、メールアドレスを登録してください。'),
              const SizedBox(height: 20),
              CustomTextFormField(
                controller: _emailController,
                labelText: 'メールアドレス',
                validator: (value) {
                  if (value == null || value.trim().isEmpty || !value.contains('@')) {
                    return '有効なメールアドレスを入力してください';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _goToNextStep,
                text: '次へ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
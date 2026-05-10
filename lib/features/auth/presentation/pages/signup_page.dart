import 'package:flutter/material.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/terms_of_service_page.dart'; // 追加
import 'package:amplify_flutter/amplify_flutter.dart'; 

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isAgreed = false; // 規約同意の状態

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 利用規約画面へ遷移し、結果を受け取る
  Future<void> _navigateToTerms() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
    );

    if (result == true) {
      setState(() {
        _isAgreed = true;
      });
    }
  }

  void _goToNextStep() async {
    if (_formKey.currentState!.validate()) {
      // 念のためロジック側でもチェック（ボタンが無効化されていれば通常ここには来ない）
      if (!_isAgreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('利用規約への同意が必要です')),
        );
        return;
      }

      try {
        if (Amplify.isConfigured) {
           await Amplify.Auth.signOut();
        }
      } catch (e) {
        safePrint('既存セッションのサインアウトに失敗しました: $e');
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              
              const SizedBox(height: 20),

              // 利用規約同意セクション
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  value: _isAgreed,
                  onChanged: (bool? value) {
                    if (value == true) {
                      _navigateToTerms(); // チェックを入れようとしたら規約画面へ
                    } else {
                      setState(() {
                        _isAgreed = false;
                      });
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Row(
                    children: [
                      GestureDetector(
                        onTap: _navigateToTerms,
                        child: const Text(
                          "利用規約",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text("に同意する"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              PrimaryButton(
                // 規約に同意していない場合はボタンを押せないようにする
                onPressed: _isAgreed ? _goToNextStep : null,
                text: '次へ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
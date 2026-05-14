// ファイルパス: lib/features/auth/presentation/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:my_madamis_app/core/constants/terms_of_service.dart'; // ★規約クラスをインポート
import 'package:amplify_flutter/amplify_flutter.dart'; 

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasReadTerms = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 20) {
        if (!_hasReadTerms) {
          setState(() {
            _hasReadTerms = true;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent <= 0) {
        setState(() {
          _hasReadTerms = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToNextStep() async {
    if (_formKey.currentState!.validate()) {
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
      appBar: AppBar(
        title: const Text('新規登録 (1/2)'),
        elevation: 0,
      ),
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
                    'まず、メールアドレスを登録してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  
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
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    TermsOfService.title, // ★別ファイルから取得
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          TermsOfService.content, // ★別ファイルから取得
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: _hasReadTerms
                            ? (bool? value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          '利用規約を最後まで読み、同意します',
                          style: TextStyle(
                            color: _hasReadTerms ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  PrimaryButton(
                    onPressed: _agreedToTerms ? _goToNextStep : null,
                    text: '次へ',
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
// ファイルパス: lib/features/auth/presentation/pages/create_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/confirmation_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/create_profile_viewmodel.dart';

import '../notifiers/auth_state_notifier.dart';

// ★修正: パスワード表示状態を管理するため ConsumerStatefulWidget に変更
class CreateProfilePage extends ConsumerStatefulWidget {
  final String email;
  const CreateProfilePage({super.key, required this.email});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isObscure = true; // ★追加: パスワードの表示状態

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(createProfileViewModelProvider);
    final notifier = ref.read(createProfileViewModelProvider.notifier);

    ref.listen<CreateProfileState>(createProfileViewModelProvider, (prev, next) {
      if(next.status == CreateProfileStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録エラー: ${next.errorMessage}')),
        );
      }
      
      if(next.status == CreateProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('サインアップをスキップし、ログインしました。')),
        );
        ref.read(authStateNotifierProvider.notifier).setAuthenticated(next.username!);
      }
      
      if(next.status == CreateProfileStatus.requiresConfirmation) {
        final passwordForConfirmation = next.lastPassword;
        if (passwordForConfirmation == null || passwordForConfirmation.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('予期せぬエラー: パスワードが見つかりません。')),
          );
          // ※元のコードに合わせてメソッド呼び出しとして実行
          notifier.resetStateToInitial(); 
          return;
        }

         Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(
              email: widget.email, // ★ widget.email でアクセス
              password: passwordForConfirmation,
              username: _usernameController.text,
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール登録 (2/2)'),
        elevation: 0,
      ),
      // ★修正: ログイン画面と同じレイアウト(最大幅500)に統一
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
                    'アカウント情報を設定してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  
                  CustomTextFormField(
                    controller: _usernameController,
                    labelText: 'ユーザー名 *',
                    validator: (v) => (v == null || v.isEmpty) ? 'ユーザー名は必須です' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  CustomTextFormField(
                    controller: _passwordController,
                    labelText: 'パスワード (8文字以上) *',
                    obscureText: _isObscure, // ★追加: 状態を反映
                    suffixIcon: IconButton(  // ★追加: 表示切り替えアイコン
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
                    validator: (v) => (v == null || v.length < 8) ? 'パスワードは8文字以上で入力してください' : null,
                  ),
                  const SizedBox(height: 40),
                  
                  PrimaryButton(
                    text: '利用を開始する',
                    isLoading: viewModel.status == CreateProfileStatus.loading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        notifier.signUp(
                          email: widget.email, // ★ widget.email でアクセス
                          password: _passwordController.text,
                          username: _usernameController.text,
                          bio: '',
                          twitterId: '',
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
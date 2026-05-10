// ファイルパス: lib/features/auth/presentation/pages/create_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/confirmation_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/create_profile_viewmodel.dart';

import '../notifiers/auth_state_notifier.dart';

// ★修正: 状態を持つ ConsumerStatefulWidget に変更
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
  
  // ★追加: パスワードの伏せ字状態を管理する変数 (初期値は true = 隠す)
  bool _isObscure = true;

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
      // ★追加: ユーザーが既に確認済みでサインインに成功した場合
      if(next.status == CreateProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('サインアップをスキップし、ログインしました。')),
        );
        // グローバルな認証状態を更新
        ref.read(authStateNotifierProvider.notifier).setAuthenticated(next.username!);
        // この時点でHomePageに遷移します（main.dartのロジックによる）
      }
      
      if(next.status == CreateProfileStatus.requiresConfirmation) {
         // ViewModelに保存されたパスワードを安全に使用する
        final passwordForConfirmation = next.lastPassword;
        if (passwordForConfirmation == null || passwordForConfirmation.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('予期せぬエラー: パスワードが見つかりません。')),
          );
          notifier.resetStateToInitial;
          return;
        }

         // 確認画面へ遷移
         Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(
              email: widget.email, // ★ widget.email に修正
              password: passwordForConfirmation,
              username: _usernameController.text,
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール登録 (2/2)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: _usernameController,
                labelText: 'ユーザー名 *',
                validator: (v) => (v == null || v.isEmpty) ? 'ユーザー名は必須です' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _passwordController,
                labelText: 'パスワード (8文字以上) *',
                obscureText: _isObscure, // ★追加: 状態変数を使用
                suffixIcon: IconButton( // ★追加: アイコンボタンを配置
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // ★追加: ボタンが押されたら、伏せ字状態を反転して再描画
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
                validator: (v) => (v == null || v.length < 8) ? 'パスワードは8文字以上で入力してください' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: '利用を開始する',
                isLoading: viewModel.status == CreateProfileStatus.loading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    notifier.signUp(
                      email: widget.email, // ★ widget.email に修正
                      password: _passwordController.text,
                      username: _usernameController.text,
                      // 修正: bio と twitterId は空文字を渡すか、引数を省略する
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
    );
  }
}
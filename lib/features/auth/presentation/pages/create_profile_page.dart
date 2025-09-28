// ファイルパス: lib/features/auth/presentation/pages/create_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/confirmation_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/create_profile_viewmodel.dart';

class CreateProfilePage extends ConsumerWidget {
  final String email;
  const CreateProfilePage({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final bioController = TextEditingController();
    final twitterController = TextEditingController();

    final viewModel = ref.watch(createProfileViewModelProvider);
    final notifier = ref.read(createProfileViewModelProvider.notifier);

   ref.listen<CreateProfileState>(createProfileViewModelProvider, (prev, next) {
      if(next.status == CreateProfileStatus.error) {
        // エラー時はローディングが解除され、スナックバーを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録エラー: ${next.errorMessage}')),
        );
      }
      if(next.status == CreateProfileStatus.requiresConfirmation) {
         // ViewModelに保存されたパスワードを安全に使用する
        final passwordForConfirmation = next.lastPassword;
        if (passwordForConfirmation == null || passwordForConfirmation.isEmpty) {
          // パスワードが取得できない場合は、処理を中断しエラー状態にリセット
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('予期せぬエラー: パスワードが見つかりません。')),
          );
          // 状態を初期に戻して、画面が操作できるようにする
          notifier.state = notifier.state.copyWith(status: CreateProfileStatus.initial);
          return;
        }

         // 確認画面へ遷移（この遷移によってローディングが消える）
         Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(
              email: email,
              // ★修正ポイント: Stateから取得したパスワードを渡す
              password: passwordForConfirmation,
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
          key: formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: usernameController,
                labelText: 'ユーザー名 *',
                validator: (v) => (v == null || v.isEmpty) ? 'ユーザー名は必須です' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: passwordController,
                labelText: 'パスワード (8文字以上) *',
                obscureText: true,
                validator: (v) => (v == null || v.length < 8) ? 'パスワードは8文字以上で入力してください' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: bioController,
                labelText: '自己紹介 (任意)',
                maxLines: 5,
                maxLength: 200,
              ),
               const SizedBox(height: 16),
              CustomTextFormField(
                controller: twitterController,
                labelText: 'X (Twitter) ID (任意)',
                prefixText: '@',
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: '利用を開始する',
                isLoading: viewModel.status == CreateProfileStatus.loading,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    notifier.signUp(
                      email: email,
                      password: passwordController.text,
                      username: usernameController.text,
                      bio: bioController.text,
                      twitterId: twitterController.text,
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
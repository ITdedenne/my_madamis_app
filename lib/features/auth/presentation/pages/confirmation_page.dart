// ファイルパス: lib/features/auth/presentation/pages/confirmation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/confirmation_viewmodel.dart';

class ConfirmationPage extends ConsumerWidget {
  final String email;
  final String password;
  const ConfirmationPage({super.key, required this.email, required this.password});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final viewModel = ref.watch(confirmationViewModelProvider);
    final notifier = ref.read(confirmationViewModelProvider.notifier);
    
    ref.listen<ConfirmationState>(confirmationViewModelProvider, (_, next) {
      if (next.status == ConfirmationStatus.error) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      }
      if (next.status == ConfirmationStatus.success) {
                // メッセージを渡してグローバル状態を更新
        ref.read(authStateNotifierProvider.notifier).setAuthenticated(
            next.username!,
            message: '登録が完了しました。' // ★修正: メッセージを渡す
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('コード認証')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('$email に届いた確認コードを入力してください。'),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: codeController,
              labelText: '確認コード',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '認証してログイン',
              isLoading: viewModel.status == ConfirmationStatus.loading,
              onPressed: () => notifier.confirmSignUp(
                email: email,
                password: password,
                confirmationCode: codeController.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
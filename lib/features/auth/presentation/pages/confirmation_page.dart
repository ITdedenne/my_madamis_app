// ファイルパス: lib/features/auth/presentation/pages/confirmation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/confirmation_viewmodel.dart';
import '../../../home/presentation/pages/home_page.dart';

class ConfirmationPage extends ConsumerWidget {
  final String email;
  final String password;
  final String username;

  const ConfirmationPage({
    super.key,
    required this.email,
    required this.password,
    required this.username,
  });

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
        final authenticatedName = next.authenticatedUsername ?? username;
        
        ref.read(authStateNotifierProvider.notifier).setAuthenticated(
            authenticatedName, 
            message: '登録が完了しました。' 
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('コード認証'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$email に届いた\n確認コードを入力してください。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                CustomTextFormField(
                  controller: codeController,
                  labelText: '確認コード',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 40),
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
        ),
      ),
    );
  }
}
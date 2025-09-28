// ファイルパス: lib/features/settings/presentation/pages/update_email_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/confirm_update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/update_email_viewmodel.dart';

class UpdateEmailPage extends ConsumerWidget {
  const UpdateEmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final viewModel = ref.watch(updateEmailViewModelProvider);
    final notifier = ref.read(updateEmailViewModelProvider.notifier);

    ref.listen<UpdateEmailState>(updateEmailViewModelProvider, (previous, next) {
      if (next.status == UpdateEmailStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      }
      if (next.status == UpdateEmailStatus.requiresConfirmation) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmUpdateEmailPage(newEmail: emailController.text),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('メールアドレス変更')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: emailController,
                labelText: '新しいメールアドレス',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? '有効なメールアドレスを入力してください' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: '確認コードを送信',
                isLoading: viewModel.status == UpdateEmailStatus.loading,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    notifier.updateEmail(emailController.text);
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
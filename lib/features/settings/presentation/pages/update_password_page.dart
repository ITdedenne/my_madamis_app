// ファイルパス: lib/features/settings/presentation/pages/update_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/update_password_viewmodel.dart';

class UpdatePasswordPage extends ConsumerWidget {
  const UpdatePasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final viewModel = ref.watch(updatePasswordViewModelProvider);
    final notifier = ref.read(updatePasswordViewModelProvider.notifier);

    ref.listen<UpdatePasswordState>(updatePasswordViewModelProvider, (prev, next) {
       if (next.status == UpdatePasswordStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      }
      if (next.status == UpdatePasswordStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードが正常に変更されました。')),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('パスワード変更')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: oldPasswordController,
                labelText: '現在のパスワード',
                obscureText: true,
                 validator: (value) => (value == null || value.isEmpty) ? '現在のパスワードを入力してください' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: newPasswordController,
                labelText: '新しいパスワード (8文字以上)',
                obscureText: true,
                validator: (value) => (value == null || value.length < 8) ? '8文字以上で入力してください' : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'パスワードを変更',
                isLoading: viewModel.status == UpdatePasswordStatus.loading,
                onPressed: () {
                  if(formKey.currentState!.validate()) {
                    notifier.updatePassword(
                      oldPassword: oldPasswordController.text,
                      newPassword: newPasswordController.text,
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
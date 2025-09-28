// ファイルパス: lib/features/settings/presentation/pages/confirm_update_email_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/confirm_update_email_viewmodel.dart';

class ConfirmUpdateEmailPage extends ConsumerWidget {
  final String newEmail;
  const ConfirmUpdateEmailPage({super.key, required this.newEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final viewModel = ref.watch(confirmUpdateEmailViewModelProvider);
    final notifier = ref.read(confirmUpdateEmailViewModelProvider.notifier);

    ref.listen<ConfirmUpdateEmailState>(confirmUpdateEmailViewModelProvider, (prev, next) {
      if (next.status == ConfirmUpdateEmailStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      }
      if (next.status == ConfirmUpdateEmailStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メールアドレスが正常に変更されました。')),
        );
        // 設定画面まで戻る
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('確認コード入力')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('$newEmail に送信された確認コードを入力してください。'),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: codeController,
              labelText: '確認コード',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: '変更を確定',
              isLoading: viewModel.status == ConfirmUpdateEmailStatus.loading,
              onPressed: () => notifier.confirmUpdateEmail(codeController.text),
            ),
          ],
        ),
      ),
    );
  }
}
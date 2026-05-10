// ファイルパス: lib/features/auth/presentation/pages/confirmation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/confirmation_viewmodel.dart';
import '../../../home/presentation/pages/home_page.dart';

// Controllerを安全に破棄(dispose)するためにConsumerStatefulWidgetを使用します
class ConfirmationPage extends ConsumerStatefulWidget {
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
  ConsumerState<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<ConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(confirmationViewModelProvider);
    final notifier = ref.read(confirmationViewModelProvider.notifier);

    ref.listen<ConfirmationState>(confirmationViewModelProvider, (_, next) {
      if (next.status == ConfirmationStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.errorMessage}')),
        );
      } else if (next.status == ConfirmationStatus.success) {
        // ViewModelから返された正式なユーザー名を使用する
        final authenticatedName = next.authenticatedUsername ?? widget.username;

        ref.read(authStateNotifierProvider.notifier).setAuthenticated(
              authenticatedName,
              message: '登録が完了しました。',
            );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('コード認証')),
      body: Center( // ★PC対応：中央寄せ
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500), // ★PC対応：横幅制限
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // ボタンや入力欄を幅いっぱいに
                children: [
                  Text(
                    '${widget.email} に届いた確認コードを入力してください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomTextFormField(
                    controller: _codeController,
                    labelText: '確認コード',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? '確認コードを入力してください' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: '認証してログイン',
                    isLoading: viewModel.status == ConfirmationStatus.loading,
                    onPressed: () {
                      // 入力チェックを行ってからViewModelのメソッドを呼ぶ
                      if (_formKey.currentState!.validate()) {
                        notifier.confirmSignUp(
                          email: widget.email, // ★エラー解消：正しくemailを渡す
                          password: widget.password,
                          confirmationCode: _codeController.text,
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
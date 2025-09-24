// ファイルパス: lib/features/auth/presentation/pages/create_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/auth_state_notifier.dart';
import 'confirmation_page.dart';

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
  final _bioController = TextEditingController();
  final _twitterController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _onSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final notifier = ref.read(authStateNotifierProvider.notifier);
    await notifier.createProfileAndSignUp(
      email: widget.email,
      password: _passwordController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      twitterId: _twitterController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateNotifierProvider, (_, next) {
      if (next.status == AuthStatus.confirmationRequired) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(username: next.usernameForConfirmation!),
          ),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録エラー: ${next.errorMessage}')),
        );
      }
    });

    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィールとパスワードを設定')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('次に、プロフィール情報とパスワードを設定します。'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'ユーザー名 *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ユーザー名は必須です';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード (8文字以上) *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'パスワードは8文字以上で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '自己紹介 (任意)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 200,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _twitterController,
                decoration: const InputDecoration(
                  labelText: 'X (Twitter) ID (任意)',
                  border: OutlineInputBorder(),
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: authState.status == AuthStatus.loading ? null : _onSaveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : const Text('利用を開始する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
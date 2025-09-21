// ファイルパス: lib/features/profile/presentation/pages/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/profile/presentation/notifiers/profile_state_notifier.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ビルド前にProviderから安全に読み込む
    final profileState = ref.read(profileStateNotifierProvider);
    _usernameController = TextEditingController(text: profileState.username);
    _bioController = TextEditingController(text: profileState.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 保存ボタンが押されたときの処理
  Future<void> _onSave() async {
    // 入力チェック
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // ローディング開始
    setState(() => _isLoading = true);

    final notifier = ref.read(profileStateNotifierProvider.notifier);
    final success = await notifier.updateProfile(
      username: _usernameController.text,
      bio: _bioController.text,
    );

    // ローディング終了
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        // 成功したら前の画面に戻る
        Navigator.of(context).pop();
      } else {
        // 失敗したらエラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールの更新に失敗しました。')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        // ▼▼▼ AppBarのactionsを削除 ▼▼▼
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ボタンを横幅いっぱいに広げる
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'ユーザー名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ユーザー名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '自己紹介',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true, // ラベルを左上に固定
                ),
                maxLines: 5,
                maxLength: 200, // 文字数制限の例
              ),
              const SizedBox(height: 24.0),
              // ▼▼▼ 保存ボタンを追加 ▼▼▼
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onSave, // ローディング中は無効化
                icon: _isLoading
                    ? Container( // ローディングインジケーター
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('変更を保存'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
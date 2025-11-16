// ファイルパス: lib/features/profile/presentation/pages/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final UserProfile initialProfile;
  const EditProfilePage({super.key, required this.initialProfile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  // 修正: _twitterController を削除
  // late final TextEditingController _twitterController; 
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialProfile.username);
    _bioController = TextEditingController(text: widget.initialProfile.bio);
    // 修正: _twitterController の初期化を削除
    // _twitterController = TextEditingController(text: widget.initialProfile.twitterId);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    // 修正: _twitterController の破棄を削除
    // _twitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(editProfileViewModelProvider);
    final notifier = ref.read(editProfileViewModelProvider.notifier);

    ref.listen<EditProfileState>(editProfileViewModelProvider, (previous, next) {
      if (next.status == EditProfileStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: ${next.errorMessage}')),
        );
      }
      if (next.status == EditProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: _usernameController,
                labelText: 'ユーザー名',
                validator: (value) => (value == null || value.isEmpty) ? 'ユーザー名は必須です' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _bioController,
                labelText: '自己紹介',
                maxLines: 5,
                maxLength: 160, 
              ),
              const SizedBox(height: 24), // X ID の SizedBox 削除に伴いマージ
              // ★ 修正箇所: X (Twitter) ID の入力フィールドを削除
              PrimaryButton(
                text: '変更を保存',
                isLoading: viewModelState.status == EditProfileStatus.loading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    notifier.updateProfile(
                      username: _usernameController.text,
                      bio: _bioController.text,
                      // 修正: twitterId は空文字を渡すか、引数を省略する (今回は空文字)
                      twitterId: '', 
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
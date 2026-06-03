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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.initialProfile.username);
    _bioController = TextEditingController(text: widget.initialProfile.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(editProfileViewModelProvider);
    final notifier = ref.read(editProfileViewModelProvider.notifier);

    ref.listen<EditProfileState>(editProfileViewModelProvider,
        (previous, next) {
      if (next.status == EditProfileStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: ${next.errorMessage}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.status == EditProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '基本情報',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextFormField(
                        controller: _usernameController,
                        labelText: 'ユーザー名',
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'ユーザー名は必須です'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      CustomTextFormField(
                        controller: _bioController,
                        labelText: '自己紹介',
                        maxLines: 5,
                        maxLength: 160,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: '変更を保存',
                isLoading: viewModelState.status == EditProfileStatus.loading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    notifier.updateProfile(
                      publicUserId: widget.initialProfile.publicUserId,
                      username: _usernameController.text,
                      bio: _bioController.text,
                      twitterId: '',
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
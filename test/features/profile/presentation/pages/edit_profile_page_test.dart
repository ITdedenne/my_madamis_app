// ファイルパス: test/features/profile/presentation/pages/edit_profile_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';

// Mockクラス
class MockEditProfileViewModel extends StateNotifier<EditProfileState>
    with Mock
    implements EditProfileViewModel {
  MockEditProfileViewModel(super.state);

  @override
  Future<void> updateProfile({
    String? publicUserId, // ★ 修正: String? (Null許容型) に変更
    required String username,
    required String bio,
    required String twitterId,
  }) {
    return super.noSuchMethod(
      Invocation.method(
          #updateProfile, [], {#publicUserId: publicUserId, #username: username, #bio: bio, #twitterId: twitterId}), // ★ 修正
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MockEditProfileViewModel mockViewModel;

  const initialProfile = UserProfile(
    publicUserId: 'initial_id', // ★ 追加
    username: 'initial_user',
    bio: 'initial_bio',
    twitterId: 'initial_twitter',
  );

  setUp(() {
    mockViewModel = MockEditProfileViewModel(EditProfileState());
  });

  testWidgets('フォーム入力後に保存ボタンをタップするとupdateProfileが呼ばれること', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editProfileViewModelProvider.overrideWith((ref) => mockViewModel),
        ],
        child:const MaterialApp(home: EditProfilePage(initialProfile: initialProfile)),
      ),
    );

    const newUsername = 'updated_user';
    const newBio = 'updated_bio';
    // const newTwitterId = 'updated_twitter'; // twitterIdフィールドは削除済み

    await tester.enterText(
        find.widgetWithText(TextFormField, 'ユーザー名'), newUsername);
    await tester.enterText(
        find.widgetWithText(TextFormField, '自己紹介'), newBio);
    // X (Twitter) ID の入力フィールドは削除されたため、enterTextを削除
    // ★ 修正: 存在しないフィールド 'X (Twitter) ID' のテストを削除

    await tester.tap(find.widgetWithText(PrimaryButton, '変更を保存'));

    // ★ 修正: verify の呼び出しシグネチャを合わせる
    verify(mockViewModel.updateProfile(
      publicUserId: initialProfile.publicUserId, // ★ 修正: publicUserId を渡す
      username: newUsername,
      bio: newBio,
      twitterId: '', // twitterIdは空文字を渡す仕様に変更
    )).called(1);
  });

  testWidgets('ユーザー名が未入力の場合、バリデーションエラーが表示されること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editProfileViewModelProvider.overrideWith((ref) => mockViewModel),
        ],
        child:const MaterialApp(home: EditProfilePage(initialProfile: initialProfile)),
      ),
    );

    // Act
    await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名'), '');
    await tester.enterText(
        find.widgetWithText(TextFormField, '自己紹介'), initialProfile.bio);
    // ★ 修正: 存在しないフィールド 'X (Twitter) ID' のテストを削除
    
    await tester.tap(find.widgetWithText(PrimaryButton, '変更を保存'));
    await tester.pump();

    // Assert
    expect(find.text('ユーザー名は必須です'), findsOneWidget);

    // ★ 修正: verifyNever の呼び出しシグネチャを合わせる
    verifyNever(mockViewModel.updateProfile(
      publicUserId: initialProfile.publicUserId, // ★ 修正
      username: '', 
      bio: initialProfile.bio, 
      twitterId: '',
    ));
  });
}
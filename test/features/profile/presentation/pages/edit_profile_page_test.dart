import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';

// Mockクラス (変更なし)
class MockEditProfileViewModel extends StateNotifier<EditProfileState>
    with Mock
    implements EditProfileViewModel {
  MockEditProfileViewModel(super.state);

  @override
  Future<void> updateProfile({
    required String username,
    required String bio,
    required String twitterId,
  }) {
    return super.noSuchMethod(
      Invocation.method(
          #updateProfile, [], {#username: username, #bio: bio, #twitterId: twitterId}),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MockEditProfileViewModel mockViewModel;

  const initialProfile = UserProfile(
    username: 'initial_user',
    bio: 'initial_bio',
    twitterId: 'initial_twitter',
  );

  setUp(() {
    mockViewModel = MockEditProfileViewModel(EditProfileState());
  });

  testWidgets('フォーム入力後に保存ボタンをタップするとupdateProfileが呼ばれること', (tester) async {
    // (このテストケースは変更ありません)
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
    const newTwitterId = 'updated_twitter';

    await tester.enterText(
        find.widgetWithText(TextFormField, 'ユーザー名'), newUsername);
    await tester.enterText(
        find.widgetWithText(TextFormField, '自己紹介'), newBio);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'X (Twitter) ID'), newTwitterId);

    await tester.tap(find.widgetWithText(PrimaryButton, '変更を保存'));

    verify(mockViewModel.updateProfile(
      username: newUsername,
      bio: newBio,
      twitterId: newTwitterId,
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
    // ユーザー名に不正な値（空文字）を入力
    await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名'), '');
    // 他のフィールドは初期値のまま
    await tester.enterText(
        find.widgetWithText(TextFormField, '自己紹介'), initialProfile.bio);
    await tester.enterText(find.widgetWithText(TextFormField, 'X (Twitter) ID'),
        initialProfile.twitterId);
    
    await tester.tap(find.widgetWithText(PrimaryButton, '変更を保存'));
    await tester.pump();

    // Assert
    expect(find.text('ユーザー名は必須です'), findsOneWidget);

    // 【最終的な解決策】
    // `any()` を使わず、もし呼ばれていたとしたら渡されたはずの具体的な値を指定します。
    // これにより、静的解析エラーを100%回避できます。
    verifyNever(mockViewModel.updateProfile(
      username: '', // 入力された不正な値
      bio: initialProfile.bio, // 変更されなかった他の値
      twitterId: initialProfile.twitterId,
    ));
  });
}
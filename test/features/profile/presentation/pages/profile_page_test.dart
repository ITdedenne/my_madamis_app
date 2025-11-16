// ファイルパス: test/features/profile/presentation/pages/profile_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';

// 状態を差し替えるためのFakeクラス
class FakeProfileViewModel extends StateNotifier<ProfileState>
    implements ProfileViewModel {
  FakeProfileViewModel(super.state);

  @override
  Future<void> loadUserProfile() async {
    //何もしない
  }
  
  @override
  void updateStateWithNewProfile(UserProfile newProfile) {
    state = state.copyWith(profile: newProfile);
  }
}

void main() {
  const tUserProfile = UserProfile(
    publicUserId: '1234567', // ★ 追加
    username: 'test_user',
    bio: 'Test bio content.',
    twitterId: 'twitter_user',
  );

  testWidgets('Loaded状態でプロフィール情報が正しく表示されること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(
            (ref) => FakeProfileViewModel(
              ProfileState(status: ProfileStatus.loaded, profile: tUserProfile),
            ),
          )
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    // Assert
    expect(find.text('プロフィール'), findsOneWidget);
    expect(find.text('test_user'), findsOneWidget);
    expect(find.text('Test bio content.'), findsOneWidget);
    expect(find.text('1234567'), findsOneWidget); // ★ 追加: publicUserIdの表示確認
    expect(find.byIcon(Icons.edit), findsOneWidget);
    // ★ 修正: twitterId ('@twitter_user') のアサーションは削除 (UIから削除したため)
    expect(find.text('@twitter_user'), findsNothing);
  });

  testWidgets('Loading状態でCircularProgressIndicatorが表示されること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(
            (ref) => FakeProfileViewModel(
              ProfileState(status: ProfileStatus.loading),
            ),
          )
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Error状態でエラーメッセージが表示されること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(
            (ref) => FakeProfileViewModel(
              ProfileState(status: ProfileStatus.error, errorMessage: 'An error occurred'),
            ),
          )
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    // Assert
    expect(find.text('エラー: An error occurred'), findsOneWidget);
  });

  testWidgets('編集アイコンをタップするとEditProfilePageに遷移すること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(
            (ref) => FakeProfileViewModel(
              ProfileState(status: ProfileStatus.loaded, profile: tUserProfile),
            ),
          )
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    // Act
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(EditProfilePage), findsOneWidget);
  });
}
// ファイルパス: test/features/profile/presentation/pages/profile_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';

class FakeProfileViewModel extends StateNotifier<ProfileState>
    implements ProfileViewModel {
  FakeProfileViewModel(super.state);

  @override
  Future<void> loadUserProfile() async {}

  @override
  void updateStateWithNewProfile(UserProfile newProfile) {
    state = state.copyWith(profile: newProfile);
  }
}

void main() {
  const tUserProfile = UserProfile(
    publicUserId: '1234567',
    username: 'test_user',
    bio: 'Test bio content.',
    twitterId: 'twitter_user',
  );

  Future<void> pumpPage(WidgetTester tester, ProfileState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewModelProvider.overrideWith(
            (ref) => FakeProfileViewModel(state),
          )
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
  }

  group('プロフィール表示（正常系）', () {
    testWidgets('プロフィールデータがロードされている場合、正しく表示されること', (tester) async {
      await pumpPage(tester, ProfileState(status: ProfileStatus.loaded, profile: tUserProfile));

      expect(find.text('プロフィール'), findsOneWidget);
      expect(find.text('test_user'), findsOneWidget);
      expect(find.text('Test bio content.'), findsOneWidget);
      expect(find.text('1234567'), findsOneWidget);
      
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('編集ボタンをタップすると編集ページへ遷移すること', (tester) async {
      await pumpPage(tester, ProfileState(status: ProfileStatus.loaded, profile: tUserProfile));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfilePage), findsOneWidget);
    });
  });

  group('状態管理（異常系・ロード中）', () {
    testWidgets('ロード中はインジケーターが表示されること', (tester) async {
      await pumpPage(tester, ProfileState(status: ProfileStatus.loading));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('エラー発生時はエラーメッセージが表示されること', (tester) async {
      const errorMessage = 'An error occurred';
      await pumpPage(tester, ProfileState(status: ProfileStatus.error, errorMessage: errorMessage));

      expect(find.text('エラー: $errorMessage'), findsOneWidget);
    });
  });
}
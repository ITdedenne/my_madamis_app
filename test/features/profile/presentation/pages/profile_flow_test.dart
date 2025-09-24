// ファイルパス: test/features/profile/presentation/pages/profile_flow_test.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  Widget createTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: MaterialApp(home: child),
    );
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  // --- ▼▼▼ ここから修正 ▼▼▼ ---
  const initialUsername = 'initial_user';
  const initialBio = 'Initial bio text.';
  const initialTwitterId = 'initial_twitter'; // 初期Twitter IDを追加
  final initialAttributes = {
    AuthUserAttributeKey.preferredUsername: initialUsername,
    const CognitoUserAttributeKey.custom('bio'): initialBio,
    const CognitoUserAttributeKey.custom('twitter_id'): initialTwitterId, // 初期データを追加
  };
  // --- ▲▲▲ ここまで修正 ▲▲▲ ---

  group('Profile Flow Widget Tests', () {
    testWidgets('[PROFILE-WIDGET-001] ProfilePage - ユーザー情報が正しく表示される', (tester) async {
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);

      await tester.pumpWidget(createTestApp(const ProfilePage()));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text(initialUsername), findsOneWidget);
      expect(find.text(initialBio), findsOneWidget);
      // --- ▼▼▼ ここから追加 ▼▼▼ ---
      expect(find.text('@$initialTwitterId'), findsOneWidget); // 表示を検証
      // --- ▲▲▲ ここまで追加 ▲▲▲ ---
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('[PROFILE-WIDGET-002] ProfilePage - 編集ボタンをタップすると編集画面に遷移する', (tester) async {
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);

      await tester.pumpWidget(createTestApp(const ProfilePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfilePage), findsOneWidget);
      expect(find.widgetWithText(TextFormField, initialUsername), findsOneWidget);
      expect(find.widgetWithText(TextFormField, initialBio), findsOneWidget);
      // --- ▼▼▼ ここから追加 ▼▼▼ ---
      expect(find.widgetWithText(TextFormField, initialTwitterId), findsOneWidget); // フィールドを検証
      // --- ▲▲▲ ここまで追加 ▲▲▲ ---
    });
    
    testWidgets('[PROFILE-WIDGET-003] EditProfilePage - プロフィール更新の正常系フロー', (tester) async {
      const newUsername = 'new_username';
      const newBio = 'Updated bio text!';
      const newTwitterId = 'new_twitter_id';

      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);
      
      when(mockAuthRepository.updateUserAttributes(
        username: newUsername,
        bio: newBio,
        twitterId: newTwitterId,
      )).thenAnswer((_) async {});
      
      await tester.pumpWidget(createTestApp(const ProfilePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, initialUsername), newUsername);
      await tester.enterText(find.widgetWithText(TextFormField, initialBio), newBio);
      // --- ▼▼▼ ここから追加 ▼▼▼ ---
      await tester.enterText(find.widgetWithText(TextFormField, initialTwitterId), newTwitterId); // Twitter IDの入力ステップを追加
      // --- ▲▲▲ ここまで追加 ▲▲▲ ---
      
      await tester.tap(find.text('変更を保存'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(EditProfilePage), findsNothing);
      expect(find.text(newUsername), findsOneWidget);
      expect(find.text(newBio), findsOneWidget);
      expect(find.text('@$newTwitterId'), findsOneWidget);
      expect(find.text('変更に成功しました'), findsOneWidget);
    });

    testWidgets('[PROFILE-WIDGET-004] EditProfilePage - ユーザー名が空の場合にバリデーションエラーが表示される', (tester) async {
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);

      await tester.pumpWidget(createTestApp(const ProfilePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, initialUsername), '');
      await tester.tap(find.text('変更を保存'));
      await tester.pump();

      expect(find.text('ユーザー名を入力してください'), findsOneWidget);
    });
  });
}
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

  // テスト対象のWidgetとMockをProviderScopeでラップするヘルパー
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

  const initialUsername = 'initial_user';
  const initialBio = 'Initial bio text.';
  final initialAttributes = {
    AuthUserAttributeKey.preferredUsername: initialUsername,
    const CognitoUserAttributeKey.custom('bio'): initialBio,
  };

  group('Profile Flow Widget Tests', () {
    testWidgets('[PROFILE-WIDGET-001] ProfilePage - ユーザー情報が正しく表示される', (tester) async {
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);

      await tester.pumpWidget(createTestApp(const ProfilePage()));
      
      // ローディング表示を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(); // 非同期処理の完了を待つ

      // データが表示されたことを確認
      expect(find.text(initialUsername), findsOneWidget);
      expect(find.text(initialBio), findsOneWidget);
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
      // 編集画面のフィールドに初期値が設定されていることを確認
      expect(find.widgetWithText(TextFormField, initialUsername), findsOneWidget);
      expect(find.widgetWithText(TextFormField, initialBio), findsOneWidget);
    });
    
    testWidgets('[PROFILE-WIDGET-003] EditProfilePage - プロフィール更新の正常系フロー', (tester) async {
      const newUsername = 'new_username';
      const newBio = 'Updated bio text!';

      // 1. 初期データの準備
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);
      
      // 2. 更新処理のモック
      when(mockAuthRepository.updateUserAttributes(username: newUsername, bio: newBio))
          .thenAnswer((_) async {});
      
      // 3. ProfilePageを描画
      await tester.pumpWidget(createTestApp(const ProfilePage()));
      await tester.pumpAndSettle();

      // 4. 編集画面へ遷移
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 5. テキストを入力
      await tester.enterText(find.widgetWithText(TextFormField, initialUsername), newUsername);
      await tester.enterText(find.widgetWithText(TextFormField, initialBio), newBio);
      
      // 6. 保存ボタンをタップ
      await tester.tap(find.text('変更を保存'));
      await tester.pumpAndSettle(); // 画面遷移と状態更新を待つ

      // 7. ProfilePageに戻り、UIが更新されたことを確認
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(EditProfilePage), findsNothing);
      expect(find.text(newUsername), findsOneWidget); // 更新後の名前が表示されている
      expect(find.text(newBio), findsOneWidget);      // 更新後の自己紹介が表示されている
      expect(find.text('変更に成功しました'), findsOneWidget); // SnackBarが表示される
    });

    testWidgets('[PROFILE-WIDGET-004] EditProfilePage - ユーザー名が空の場合にバリデーションエラーが表示される', (tester) async {
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => initialAttributes);

      await tester.pumpWidget(createTestApp(const ProfilePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // ユーザー名を空にする
      await tester.enterText(find.widgetWithText(TextFormField, initialUsername), '');
      await tester.tap(find.text('変更を保存'));
      await tester.pump(); // バリデーションエラーの表示を待つ

      expect(find.text('ユーザー名を入力してください'), findsOneWidget);
    });
  });
}
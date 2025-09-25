// ファイルパス: test/features/settings/presentation/pages/settings_flow_test.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/confirm_update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/settings_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_password_page.dart';
import 'package:my_madamis_app/main.dart' as app;

import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  // テストウィジェットをラップするヘルパー
  Widget createTestApp({required Widget home}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      // MaterialAppでラップすることで、実際のアプリに近い環境でテストを実行
      child: app.MyApp(home: home),
    );
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // ログイン済みの状態をモック
    when(mockAuthRepository.fetchUserAttributes()).thenAnswer((_) async => [
          const AuthUserAttribute(
              userAttributeKey: AuthUserAttributeKey.preferredUsername,
              value: 'test_user')
        ]);
  });

  group('設定フロー ウィジェットテスト', () {
    testWidgets('[SETTINGS-FLOW-001] ホーム画面から設定画面への遷移', (tester) async {
      await tester.pumpWidget(createTestApp(home: const HomePage()));
      await tester.pumpAndSettle();

      // 歯車アイコンをタップ
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 設定画面が表示されていることを確認
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('メールアドレス変更'), findsOneWidget);
      expect(find.text('パスワード変更'), findsOneWidget);
    });

    group('メールアドレス変更フロー', () {
      const newEmail = 'new.user@example.com';
      const confirmationCode = '123456';

      testWidgets('[SETTINGS-FLOW-002] 正常なメールアドレス変更フロー', (tester) async {
        // --- モックの設定 ---
        when(mockAuthRepository.updateEmail(any)).thenAnswer((_) async =>
            const UpdateUserAttributeResult(
                isUpdated: false,
                nextStep: AuthNextUpdateAttributeStep(
                    updateAttributeStep:
                        AuthUpdateAttributeStep.confirmAttributeWithCode)));

        when(mockAuthRepository.confirmUpdateEmail(any))
            .thenAnswer((_) async {});

        // --- テスト実行 ---
        await tester.pumpWidget(createTestApp(home: const HomePage()));
        await tester.pumpAndSettle();

        // 1. 設定画面に遷移
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);

        // 2. メールアドレス変更画面に遷移
        await tester.tap(find.text('メールアドレス変更'));
        await tester.pumpAndSettle();
        expect(find.byType(UpdateEmailPage), findsOneWidget);

        // 3. 新しいメールアドレスを入力してコードを送信
        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいメールアドレス'), newEmail);
        await tester.tap(find.text('確認コードを送信'));
        await tester.pumpAndSettle(); // 画面遷移を待つ

        // 4. 確認画面に遷移したことを確認
        expect(find.byType(ConfirmUpdateEmailPage), findsOneWidget);
        expect(find.textContaining(newEmail), findsOneWidget);

        // 5. 確認コードを入力して変更を確定
        await tester.enterText(
            find.widgetWithText(TextFormField, '確認コード'), confirmationCode);
        await tester.tap(find.text('変更を確定'));
        await tester.pumpAndSettle(); // 状態更新と画面遷移を待つ

        // --- 検証 ---
        // 6. 設定画面に戻り、成功のSnackBarが表示されることを確認
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.text('メールアドレスが正常に変更されました。'), findsOneWidget);
      });

      testWidgets('[SETTINGS-FLOW-003] 確認コードが間違っている場合にエラーが表示される',
          (tester) async {
        // --- モックの設定 ---
        when(mockAuthRepository.updateEmail(any)).thenAnswer((_) async =>
            const UpdateUserAttributeResult(
                isUpdated: false,
                nextStep: AuthNextUpdateAttributeStep(
                    updateAttributeStep:
                        AuthUpdateAttributeStep.confirmAttributeWithCode)));

        // コード不一致例外をスローするように設定
        when(mockAuthRepository.confirmUpdateEmail(any))
            .thenThrow(const CodeMismatchException('Invalid code'));

        // --- テスト実行 ---
        await tester.pumpWidget(createTestApp(home: const SettingsPage()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('メールアドレス変更'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいメールアドレス'), newEmail);
        await tester.tap(find.text('確認コードを送信'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.widgetWithText(TextFormField, '確認コード'), 'wrong-code');
        await tester.tap(find.text('変更を確定'));
        await tester.pumpAndSettle();

        // --- 検証 ---
        // 確認画面に留まり、エラーメッセージが表示されることを確認
        expect(find.byType(ConfirmUpdateEmailPage), findsOneWidget);
        expect(find.textContaining('メールアドレスの変更に失敗しました'), findsOneWidget);
      });
    });

    group('パスワード変更フロー', () {
      const oldPassword = 'oldPassword123';
      const newPassword = 'newPassword123';

      testWidgets('[SETTINGS-FLOW-004] 正常なパスワード変更フロー', (tester) async {
        // --- モックの設定 ---
        when(mockAuthRepository.updatePassword(
                oldPassword: oldPassword, newPassword: newPassword))
            .thenAnswer((_) async {});

        // --- テスト実行 ---
        await tester.pumpWidget(createTestApp(home: const HomePage()));
        await tester.pumpAndSettle();

        // 1. 設定画面 > パスワード変更画面へ
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        await tester.tap(find.text('パスワード変更'));
        await tester.pumpAndSettle();
        expect(find.byType(UpdatePasswordPage), findsOneWidget);

        // 2. パスワードを入力して変更ボタンをタップ
        await tester.enterText(
            find.widgetWithText(TextFormField, '現在のパスワード'), oldPassword);
        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいパスワード (8文字以上)'),
            newPassword);
        await tester.tap(find.text('パスワードを変更'));
        await tester.pumpAndSettle();

        // --- 検証 ---
        // 3. 設定画面に戻り、成功のSnackBarが表示されることを確認
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.text('パスワードが正常に変更されました。'), findsOneWidget);
      });

      testWidgets('[SETTINGS-FLOW-005] 古いパスワードが間違っている場合にエラーが表示される',
          (tester) async {
        // --- モックの設定 ---
        when(mockAuthRepository.updatePassword(
                oldPassword: 'wrong-old-password', newPassword: newPassword))
            .thenThrow(const NotAuthorizedServiceException('Incorrect password'));

        // --- テスト実行 ---
        await tester.pumpWidget(createTestApp(home: const SettingsPage()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('パスワード変更'));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.widgetWithText(TextFormField, '現在のパスワード'),
            'wrong-old-password');
        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいパスワード (8文字以上)'),
            newPassword);
        await tester.tap(find.text('パスワードを変更'));
        await tester.pumpAndSettle();

        // --- 検証 ---
        // パスワード変更画面に留まり、エラーメッセージが表示されることを確認
        expect(find.byType(UpdatePasswordPage), findsOneWidget);
        expect(find.textContaining('パスワードの変更に失敗しました'), findsOneWidget);
      });

      testWidgets('[SETTINGS-FLOW-006] 新しいパスワードがポリシー違反の場合にエラーが表示される',
          (tester) async {
        // --- モックの設定 ---
        when(mockAuthRepository.updatePassword(
                oldPassword: oldPassword, newPassword: 'short'))
            .thenThrow(const InvalidPasswordException('Password is too short'));

        // --- テスト実行 ---
        await tester.pumpWidget(createTestApp(home: const SettingsPage()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('パスワード変更'));
        await tester.pumpAndSettle();

        // バリデーション自体は通るがAPIでエラーになるケースを想定
        await tester.enterText(
            find.widgetWithText(TextFormField, '現在のパスワード'), oldPassword);
        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいパスワード (8文字以上)'), 'short');
        await tester.tap(find.text('パスワードを変更'));
        await tester.pumpAndSettle();

        // --- 検証 ---
        expect(find.byType(UpdatePasswordPage), findsOneWidget);
        expect(find.textContaining('パスワードの変更に失敗しました'), findsOneWidget);
      });

        testWidgets('[SETTINGS-FLOW-007] パスワード入力フォームのクライアントサイドバリデーションが機能する',
          (tester) async {

        await tester.pumpWidget(createTestApp(home: const UpdatePasswordPage()));
        await tester.pumpAndSettle();

        // 何も入力せずにボタンをタップ
        await tester.tap(find.text('パスワードを変更'));
        await tester.pump(); // 1フレーム進めてバリデーションエラーの表示を待つ

        // エラーメッセージが表示されることを確認
        expect(find.text('現在のパスワードを入力してください'), findsOneWidget);
        expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);

        // 短いパスワードを入力
        await tester.enterText(find.widgetWithText(TextFormField, '新しいパスワード (8文字以上)'), '123');
        await tester.tap(find.text('パスワードを変更'));
        await tester.pump();

        // エラーメッセージが依然として表示されていることを確認
        expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
      });
    });
  });
}
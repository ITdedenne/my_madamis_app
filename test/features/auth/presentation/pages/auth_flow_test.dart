// ファイルパス: test/features/auth/presentation/pages/auth_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';
import 'package:my_madamis_app/main.dart' as app;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/reset_password_page.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockResetPasswordResult mockResetPasswordResult;

  Widget createTestApp(MockAuthRepository repository) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const app.MyApp(),
    );
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockResetPasswordResult = MockResetPasswordResult();
  });

  group('認証フロー ウィジェットテスト', () {
    group('ログイン画面', () {
      testWidgets('[AUTH-WIDGET-001] 正常なログインフロー', (WidgetTester tester) async {
        // --- ここから修正 ---
        when(mockAuthRepository.signIn(
          username: 'test@example.com',
          password: 'password',
        )).thenAnswer((_) async => const SignInResult(
              isSignedIn: true,
              nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
            ));

        when(mockAuthRepository.fetchUserAttributes()).thenAnswer((_) async => [
              const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: 'test user',
              )
            ]);
        // --- ここまで修正 ---

        await tester.pumpWidget(createTestApp(mockAuthRepository));
        await tester.enterText(
            find.widgetWithText(TextFormField, 'メールアドレス'), 'test@example.com');
        await tester.enterText(
            find.widgetWithText(TextFormField, 'パスワード'), 'password');
        
        await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
      });

      testWidgets('[AUTH-WIDGET-002] パスワード間違いでエラーメッセージが表示される',
          (WidgetTester tester) async {
        when(mockAuthRepository.signIn(
          username: anyNamed('username'),
          password: anyNamed('password'),
        )).thenThrow(
            const NotAuthorizedServiceException('Incorrect username or password.'));

        await tester.pumpWidget(createTestApp(mockAuthRepository));
        await tester.enterText(
            find.widgetWithText(TextFormField, 'メールアドレス'), 'test@example.com');
        await tester.enterText(
            find.widgetWithText(TextFormField, 'パスワード'), 'wrong_password');
        await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
        await tester.pumpAndSettle();
        expect(find.textContaining('エラー: ログインに失敗しました'), findsOneWidget);
      });
    });

    group('パスワードリセットフロー', () {
      testWidgets('[AUTH-WIDGET-003] 正常なパスワードリセットフロー',
          (WidgetTester tester) async {
        const mockStep = ResetPasswordStep(
          updateStep: AuthResetPasswordStep.confirmResetPasswordWithCode,
        );
        when(mockResetPasswordResult.nextStep).thenReturn(mockStep);
        when(mockResetPasswordResult.isPasswordReset).thenReturn(false);
        when(mockAuthRepository.resetPassword(any))
            .thenAnswer((_) async => mockResetPasswordResult);
        when(mockAuthRepository.confirmResetPassword(
          username: anyNamed('username'),
          newPassword: anyNamed('newPassword'),
          confirmationCode: anyNamed('confirmationCode'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(createTestApp(mockAuthRepository));
        
        await tester.tap(find.text('パスワードを忘れた場合はこちら'));
        await tester.pumpAndSettle();
        expect(find.byType(ForgotPasswordPage), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextFormField, '登録したメールアドレス'), 'test@example.com');
        await tester.tap(find.text('リセットコードを送信'));
        await tester.pumpAndSettle();
        expect(find.byType(ResetPasswordPage), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいパスワード'), 'newPassword123');
        await tester.enterText(find.widgetWithText(TextFormField, '新しいパスワードを再入力'),
            'newPassword123');
        await tester.enterText(
            find.widgetWithText(TextFormField, '認証コード'), '123456');
        await tester.tap(find.text('パスワードを更新'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.text('パスワードが正常にリセットされました。ログインしてください。'), findsOneWidget);
      });

      testWidgets('[AUTH-WIDGET-004] 未登録メールアドレスでエラーメッセージが表示される',
          (WidgetTester tester) async {
        when(mockAuthRepository.resetPassword(any))
            .thenThrow(const UserNotFoundException( 'User not found.'));
        
        await tester.pumpWidget(createTestApp(mockAuthRepository));
        await tester.tap(find.text('パスワードを忘れた場合はこちら'));
        await tester.pumpAndSettle();
        
        await tester.enterText(find.widgetWithText(TextFormField, '登録したメールアドレス'),
            'unregistered@example.com');
        await tester.tap(find.text('リセットコードを送信'));
        await tester.pumpAndSettle();

        expect(find.text('エラー: 登録されていないメールアドレスです'), findsOneWidget);
      });

       testWidgets('[AUTH-WIDGET-005] パスワード再設定で認証コードが違う場合にエラーが表示される',
          (WidgetTester tester) async {
        when(mockAuthRepository.confirmResetPassword(
          username: anyNamed('username'),
          newPassword: anyNamed('newPassword'),
          confirmationCode: anyNamed('confirmationCode'),
        )).thenThrow(const CodeMismatchException('Invalid code'));
        
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: const MaterialApp(
              home: ResetPasswordPage(username: 'test@example.com'),
            ),
          ),
        );

        await tester.enterText(
            find.widgetWithText(TextFormField, '新しいパスワード'), 'newPassword123');
        await tester.enterText(find.widgetWithText(TextFormField, '新しいパスワードを再入力'),
            'newPassword123');
        await tester.enterText(
            find.widgetWithText(TextFormField, '認証コード'), 'wrong-code');
        await tester.tap(find.text('パスワードを更新'));
        await tester.pumpAndSettle();

        expect(find.text('エラー: 認証コードが間違っています。'), findsOneWidget);
      });
    });
  });
}
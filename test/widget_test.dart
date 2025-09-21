// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/main.dart';
import 'package:my_madamis_app/pages/forgot_password_page.dart';
import 'package:my_madamis_app/pages/login_page.dart';
import 'package:my_madamis_app/pages/reset_password_page.dart';

void main() {
  testWidgets('Password Reset Flow Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that LoginPage is shown.
    expect(find.byType(LoginPage), findsOneWidget);

    // Tap the 'パスワードを忘れた場合はこちら' button.
    await tester.tap(find.text('パスワードを忘れた場合はこちら'));
    await tester.pumpAndSettle();

    // Verify that ForgotPasswordPage is shown.
    expect(find.byType(ForgotPasswordPage), findsOneWidget);

    // Enter an email and tap '送信'.
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();

    // This part is tricky to test without a mocked backend,
    // as it depends on Amplify's response.
    // For a real app, you'd use a mock of AuthRepository.
    // Assuming the navigation to ResetPasswordPage is successful.
    // We can manually pump the ResetPasswordPage for testing its UI.

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResetPasswordPage(username: 'test@example.com'),
        ),
      ),
    );

    // Verify that ResetPasswordPage is shown.
    expect(find.byType(ResetPasswordPage), findsOneWidget);

    // Enter new password, confirmation, and code.
    await tester.enterText(find.widgetWithText(TextFormField, '新しいパスワード'), 'newPassword123');
    await tester.enterText(find.widgetWithText(TextFormField, '新しいパスワードを再入力'), 'newPassword123');
    await tester.enterText(find.widgetWithText(TextFormField, '認証コード'), '123456');

    // Tap 'パスワードを更新'.
    await tester.tap(find.text('パスワードを更新'));
    await tester.pumpAndSettle();

    // Again, this depends on the backend. In a real test environment with mocks,
    // you would verify that the state notifier is called with the correct parameters
    // and that the app navigates back to the LoginPage upon success.
  });
}
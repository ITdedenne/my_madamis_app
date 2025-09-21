// ファイルパス: test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/main.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  
  // ★ ResetPasswordResultのMockも用意
  late MockResetPasswordResult mockResetPasswordResult;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    
    // ★ ResetPasswordResultのMockをインスタンス化
    mockResetPasswordResult = MockResetPasswordResult();
  });

  group('Password Reset Flow Tests', () {
    testWidgets('Successful password reset flow', (WidgetTester tester) async {
      // --- 1. 準備 (Arrange) ---

      // ★★★ ここからが修正箇所 ★★★
      // 1. 返却するステップを定義
      final mockResetPasswordStep = ResetPasswordStep(
        updateStep: AuthResetPasswordStep.confirmResetPasswordWithCode,
      );
      // 2. Mockの結果オブジェクトに、ステップと状態を設定
      when(mockResetPasswordResult.nextStep).thenReturn(mockResetPasswordStep);
      when(mockResetPasswordResult.isPasswordReset).thenReturn(false);

      // 3. AuthRepositoryのresetPasswordが呼ばれたら、上で設定したMockの結果オブジェクトを返すように設定
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => mockResetPasswordResult);
      // ★★★ ここまでが修正箇所 ★★★

      // confirmResetPasswordが成功した時のMockの挙動を設定
      when(mockAuthRepository.confirmResetPassword(
        username: anyNamed('username'),
        newPassword: anyNamed('newPassword'),
        confirmationCode: anyNamed('confirmationCode'),
      )).thenAnswer((_) async {});

      // --- 2. 実行 (Act) & 3. 検証 (Assert) ---
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MyApp(),
        ),
      );

      // (以降のテストコードは変更なし)
      await tester.tap(find.text('パスワードを忘れた場合はこちら'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.enterText(
          find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('リセットコードを送信'));
      await tester.pumpAndSettle();
      
      expect(find.byType(ResetPasswordPage), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, '新しいパスワード'), 'newPassword123');
      await tester.enterText(
          find.widgetWithText(TextFormField, '新しいパスワードを再入力'),
          'newPassword123');
      await tester.enterText(
          find.widgetWithText(TextFormField, '認証コード'), '123456');
      await tester.tap(find.text('パスワードを更新'));
      await tester.pumpAndSettle(); 
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('パスワードが正常にリセットされました。ログインしてください。'), findsOneWidget);
    });
    
    // (他のテストケースは変更なし)
  });
}
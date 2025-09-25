// ファイルパス: test/features/auth/presentation/pages/signup_flow_test.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/confirmation_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/signup_page.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';
import 'package:my_madamis_app/main.dart' as app;

import '../../../../mocks.mocks.dart';

// main.dartのMyAppにアクセスするためのヘルパー
class TestApp extends app.MyApp {
  const TestApp({super.key, required Widget home}) : super(home: home);
}

void main() {
  late MockAuthRepository mockAuthRepository;

  // テストウィジェットをラップするヘルパー
  Widget createTestApp({required Widget home}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: TestApp(home: home),
    );
  }

  // 各テストの前にMockを初期化
  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('新規登録フロー ウィジェットテスト', () {
    const testEmail = 'new_user@example.com';
    const testPassword = 'password123';
    const testUsername = 'New User';
    const testConfirmationCode = '123456';

    // 正常なサインアップ処理のモックをセットアップするヘルパー
    void setupSuccessfulSignUpMocks() {
      // 1. サインアップ処理
      when(mockAuthRepository.signUpWithProfile(
        email: anyNamed('email'),
        password: anyNamed('password'),
        username: anyNamed('username'),
        bio: anyNamed('bio'),
        twitterId: anyNamed('twitterId'),
      )).thenAnswer((_) async => const SignUpResult(
            isSignUpComplete: false, // 確認コードが必要な状態
            nextStep: AuthNextSignUpStep(
              signUpStep: AuthSignUpStep.confirmSignUp,
            ),
          ));

      // 2. 確認コード認証
      // ▼▼▼ `nextStep` に正しい値を設定 ▼▼▼
      when(mockAuthRepository.confirmSignUp(
        username: anyNamed('username'),
        confirmationCode: anyNamed('confirmationCode'),
      )).thenAnswer((_) async => const SignUpResult(
            isSignUpComplete: true,
            nextStep: AuthNextSignUpStep(signUpStep: AuthSignUpStep.done),
          ));
      
      // 3. 自動サインイン
      when(mockAuthRepository.signIn(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const SignInResult(
            isSignedIn: true,
            nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
          ));
      
      // 4. ユーザー属性の取得
      when(mockAuthRepository.fetchUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: testUsername)
          ]);
    }

    testWidgets('[SIGNUP-FLOW-001] 全項目を入力して正常に登録完了し、ホーム画面に遷移する',
        (tester) async {
      setupSuccessfulSignUpMocks();

      // --- 実行 ---
      await tester.pumpWidget(createTestApp(home: const LoginPage()));
      
      // 1. ログイン画面から新規登録画面へ
      await tester.tap(find.widgetWithText(OutlinedButton, '新規登録'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);

      // 2. メールアドレスを入力してプロフィール作成画面へ
      await tester.enterText(find.byType(TextFormField), testEmail);
      await tester.tap(find.widgetWithText(ElevatedButton, '次へ'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateProfilePage), findsOneWidget);

      // 3. プロフィールとパスワードを入力して「利用を開始する」
      await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名 *'), testUsername);
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード (8文字以上) *'), testPassword);
      await tester.enterText(find.widgetWithText(TextFormField, '自己紹介 (任意)'), 'Hello!');
      await tester.enterText(find.widgetWithText(TextFormField, 'X (Twitter) ID (任意)'), 'flutterdev');
      await tester.tap(find.widgetWithText(ElevatedButton, '利用を開始する'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationPage), findsOneWidget);

      // 4. 確認コードを入力して認証
      await tester.enterText(find.widgetWithText(TextFormField, '認証コード'), testConfirmationCode);
      await tester.tap(find.widgetWithText(ElevatedButton, '認証'));
      await tester.pumpAndSettle();

      // --- 検証 ---
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('ようこそ！$testUsernameさん！ログインに成功しました。'), findsOneWidget);
    });
    
    testWidgets('[SIGNUP-FLOW-002] 任意項目を空で正常に登録完了し、ホーム画面に遷移する',
        (tester) async {
      setupSuccessfulSignUpMocks();

      // --- 実行 ---
      await tester.pumpWidget(createTestApp(home: const LoginPage()));
      await tester.tap(find.widgetWithText(OutlinedButton, '新規登録'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), testEmail);
      await tester.tap(find.widgetWithText(ElevatedButton, '次へ'));
      await tester.pumpAndSettle();

      // 任意項目は入力しない
      await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名 *'), testUsername);
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード (8文字以上) *'), testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, '利用を開始する'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, '認証コード'), testConfirmationCode);
      await tester.tap(find.widgetWithText(ElevatedButton, '認証'));
      await tester.pumpAndSettle();

      // --- 検証 ---
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('[SIGNUP-FLOW-003] 登録済みのメールアドレスで登録しようとすると、コード再送の案内が出て確認画面に遷移する',
        (tester) async {
      // 登録済みユーザーエラーを返すようにモックを設定
      when(mockAuthRepository.signUpWithProfile(
        email: anyNamed('email'),
        password: anyNamed('password'),
        username: anyNamed('username'),
        bio: anyNamed('bio'),
        twitterId: anyNamed('twitterId'),
      )).thenThrow(const UsernameExistsException( 'User already exists'));
      
      // コード再送は成功させる
      when(mockAuthRepository.resendSignUpCode(username: anyNamed('username')))
          .thenAnswer((_) async {});
      
      // --- 実行 ---
      await tester.pumpWidget(createTestApp(home: const SignUpPage()));
      await tester.enterText(find.byType(TextFormField), testEmail);
      await tester.tap(find.widgetWithText(ElevatedButton, '次へ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名 *'), testUsername);
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード (8文字以上) *'), testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, '利用を開始する'));
      await tester.pumpAndSettle();

      // --- 検証 ---
      expect(find.byType(ConfirmationPage), findsOneWidget);
      expect(find.text('このメールアドレスは登録済みです。確認コードを再送信しました。'), findsOneWidget);
    });

    testWidgets('[SIGNUP-FLOW-004] 未確認ユーザーがログインしようとすると、コード再送の案内が出て確認画面に遷移する',
        (tester) async {
      // 未確認ユーザーエラーを返すようにモックを設定
      when(mockAuthRepository.signIn(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenThrow(const UserNotConfirmedException( 'User is not confirmed.'));
      
      // コード再送は成功させる
      when(mockAuthRepository.resendSignUpCode(username: anyNamed('username')))
          .thenAnswer((_) async {});
      
      // --- 実行 ---
      await tester.pumpWidget(createTestApp(home: const LoginPage()));
      await tester.enterText(find.widgetWithText(TextFormField, 'メールアドレス'), testEmail);
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード'), testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
      await tester.pumpAndSettle();
      
      // --- 検証 ---
      expect(find.byType(ConfirmationPage), findsOneWidget);
      expect(find.text('このアカウントは未確認です。確認コードをメールアドレスに送信しました。'), findsOneWidget);
    });

    testWidgets('[SIGNUP-FLOW-005] 確認コードを間違えるとエラーメッセージが表示される',
        (tester) async {
      setupSuccessfulSignUpMocks();
      // 確認コードのモックのみ上書き
      when(mockAuthRepository.confirmSignUp(
        username: anyNamed('username'),
        confirmationCode: 'wrong-code',
      )).thenThrow(const CodeMismatchException('Invalid code'));

      // --- 実行 ---
      await tester.pumpWidget(createTestApp(home: const SignUpPage()));
      await tester.enterText(find.byType(TextFormField), testEmail);
      await tester.tap(find.widgetWithText(ElevatedButton, '次へ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名 *'), testUsername);
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード (8文字以上) *'), testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, '利用を開始する'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.widgetWithText(TextFormField, '認証コード'), 'wrong-code');
      await tester.tap(find.widgetWithText(ElevatedButton, '認証'));
      await tester.pumpAndSettle();

      // --- 検証 ---
      expect(find.byType(ConfirmationPage), findsOneWidget); // 画面はそのまま
      expect(find.byType(HomePage), findsNothing);
      expect(find.textContaining('エラー: 認証に失敗しました'), findsOneWidget);
    });
  });
}


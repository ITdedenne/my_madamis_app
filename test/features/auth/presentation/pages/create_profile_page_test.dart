import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/create_profile_viewmodel.dart';

// CreateProfileViewModelのモック
class MockCreateProfileViewModel extends StateNotifier<CreateProfileState>
    with Mock
    implements CreateProfileViewModel {
  MockCreateProfileViewModel() : super(CreateProfileState());
}

// CreateProfilePageが依存しているAuthStateNotifierのモックも用意
class MockAuthStateNotifier extends StateNotifier<AuthState>
    with Mock
    implements AuthStateNotifier {
  MockAuthStateNotifier() : super(const AuthState());
}


void main() {
  late MockCreateProfileViewModel mockCreateProfileViewModel;
  late MockAuthStateNotifier mockAuthStateNotifier;

  // テスト対象のWidgetを準備するヘルパー関数
  Future<void> pumpCreateProfilePage(WidgetTester tester) async {
    // モックのインスタンスを作成
    mockCreateProfileViewModel = MockCreateProfileViewModel();
    mockAuthStateNotifier = MockAuthStateNotifier();

    // Widgetツリーを構築し、Providerをモックに差し替える
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // --- ▼▼▼ ここを修正 ▼▼▼ ---
          // overrideWithValueの代わりに `overrideWith` を使用する
          createProfileViewModelProvider.overrideWith((ref) => mockCreateProfileViewModel),
          // このWidgetはauthStateNotifierProviderも参照しているため、同様にモック化する
          authStateNotifierProvider.overrideWith((ref) => mockAuthStateNotifier),
          // --- ▲▲▲ ここまで修正 ▲▲▲ ---
        ],
        child: const MaterialApp(home: CreateProfilePage(email: 'test@example.com')),
      ),
    );
  }

  group('CreateProfilePage Widget Tests', () {
    testWidgets('必須項目が未入力の場合、バリデーションエラーが表示されること', (tester) async {
      // Arrange
      await pumpCreateProfilePage(tester);

      // Act
      await tester.tap(find.text('利用を開始する'));
      await tester.pump(); // バリデーションが走り、UIが更新されるのを待つ

      // Assert
      expect(find.text('ユーザー名は必須です'), findsOneWidget);
      expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
    });

    testWidgets('正常に入力してボタンをタップすると、signUpが呼ばれること', (tester) async {
      // Arrange
      await pumpCreateProfilePage(tester);
      // signUpメソッドが呼ばれた際の振る舞いを定義
      when(mockCreateProfileViewModel.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        username: anyNamed('username'),
        bio: anyNamed('bio'),
        twitterId: anyNamed('twitterId'),
      )).thenAnswer((_) async {});

      // Act
      await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名 *'), 'test_user');
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード (8文字以上) *'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, '自己紹介 (任意)'), 'hello');

      await tester.tap(find.text('利用を開始する'));

      // Assert
      // signUpメソッドが正しい引数で1回呼ばれたことを検証
      verify(mockCreateProfileViewModel.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'test_user',
        bio: 'hello',
        twitterId: '',
      )).called(1);
    });
  });
}
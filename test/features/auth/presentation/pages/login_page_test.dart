import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';

import '../../../../mocks/mocks.mocks.dart';

// ★修正: StateNotifierのモックは、振る舞いを定義したいメソッドを持つシンプルなMockクラスで十分
class MockLoginViewModel extends Mock implements LoginViewModel {
  // stateをスタブするために、実際のStateNotifierのインスタンスを持つ
  final StateNotifierProviderRef<LoginViewModel, LoginState> ref;
  final _stateNotifier = LoginViewModel(MockAuthRepository()); // ダミーのリポジトリ
  MockLoginViewModel(this.ref);

  @override
  LoginState get state => _stateNotifier.state;
}

// AuthStateNotifierも同様
class MockAuthStateNotifier extends Mock implements AuthStateNotifier {}

void main() {
  // Providerをオーバーライドするためのモックインスタンスを保持する変数
  late MockLoginViewModel mockLoginViewModel;
  late MockAuthStateNotifier mockAuthStateNotifier;

  testWidgets('ログインボタンをタップすると、ViewModelのsignInが呼ばれること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // ★修正: .autoDisposeを外してProviderをオーバーライド
          loginViewModelProvider.overrideWith((ref) {
            mockLoginViewModel = MockLoginViewModel(ref);
            // signInメソッドが呼ばれた際の振る舞いを定義
            when(mockLoginViewModel.signIn(any, any)).thenAnswer((_) async {});
            return mockLoginViewModel;
          }),
          authStateNotifierProvider.overrideWith((ref) {
            mockAuthStateNotifier = MockAuthStateNotifier();
            return mockAuthStateNotifier;
          }),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    const email = 'test@example.com';
    const password = 'password';

    // Act
    await tester.enterText(find.widgetWithText(TextFormField, 'メールアドレス'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'パスワード'), password);
    await tester.tap(find.widgetWithText(PrimaryButton, 'ログイン'));
    await tester.pump(); // stateの更新を反映

    // Assert
    verify(mockLoginViewModel.signIn(email, password)).called(1);
  });
}
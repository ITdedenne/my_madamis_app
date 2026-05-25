import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

// ViewModelのモッククラス
class MockLoginViewModel extends StateNotifier<LoginState>
    with Mock
    implements LoginViewModel {
  MockLoginViewModel(super.state);

  // signInメソッドの呼び出しを記録
  @override
  Future<void> signIn(String email, String password) {
    return super.noSuchMethod(
      Invocation.method(#signIn, [email, password]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockLoginViewModel mockLoginViewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();

    mockLoginViewModel = MockLoginViewModel(LoginState());
  });

  testWidgets('ログインボタンをタップすると、ViewModelのsignInが呼ばれること', (tester) async {

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 各Providerをモックで上書き
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          loginViewModelProvider.overrideWith((ref) => mockLoginViewModel),
          authStateNotifierProvider.overrideWith(
              (ref) => AuthStateNotifier(mockAuthRepository)),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    const email = 'test@example.com';
    const password = 'password';

    await tester.enterText(
        find.widgetWithText(TextFormField, 'メールアドレス'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'パスワード'), password);
    await tester.tap(find.widgetWithText(PrimaryButton, 'ログイン'));
    await tester.pump();

    verify(mockLoginViewModel.signIn(email, password)).called(1);
  });
}
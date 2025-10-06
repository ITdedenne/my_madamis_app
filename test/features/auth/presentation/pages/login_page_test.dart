import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';

// ViewModelとNotifierのモッククラス
class MockLoginViewModel extends StateNotifier<LoginState>
    with Mock implements LoginViewModel {
  MockLoginViewModel() : super(LoginState());
  @override set state(LoginState newState) => super.state = newState;
}

class MockAuthStateNotifier extends StateNotifier<AuthState>
    with Mock implements AuthStateNotifier {
  MockAuthStateNotifier() : super(const AuthState());
  @override set state(AuthState newState) => super.state = newState;
}

void main() {
  late MockLoginViewModel mockLoginViewModel;
  late MockAuthStateNotifier mockAuthStateNotifier;

  setUp(() {
    mockLoginViewModel = MockLoginViewModel();
    mockAuthStateNotifier = MockAuthStateNotifier();
  });

  // テスト対象Widgetをラップするヘルパー
  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        loginViewModelProvider.overrideWithValue(mockLoginViewModel),
        authStateNotifierProvider.overrideWithValue(mockAuthStateNotifier),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('メールアドレスが無効な場合、バリデーションエラーは出ない（ViewModelロジックのため）', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      // Widget 자체에는 validator가 없으므로 에러 텍스트는 표시되지 않는다.
      expect(find.text('有効なメールアドレスを入力してください'), findsNothing);
    });

    testWidgets('ログイン成功時、AuthStateNotifierのsetAuthenticatedが呼ばれること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      // listenしているProviderの状態を変化させる
      final container = tester.element<ProviderScope>(find.byType(ProviderScope));
      container.read(loginViewModelProvider.notifier).state = LoginState(isAuthenticated: true, username: 'test_user');
      
      await tester.pump();
      
      // setAuthenticatedが呼ばれたことを確認
      verify(mockAuthStateNotifier.setAuthenticated('test_user')).called(1);
    });

    testWidgets('エラーメッセージがある場合、SnackBarが表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      final container = tester.element<ProviderScope>(find.byType(ProviderScope));
      container.read(loginViewModelProvider.notifier).state = LoginState(errorMessage: 'Test Error');
      
      await tester.pump();
      
      expect(find.text('Test Error'), findsOneWidget);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import '../../../../mocks/mocks.mocks.dart'; 

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = LoginViewModel(mockAuthRepository);
  });

  group('LoginViewModel Tests', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUsername = 'test_user';

    const dummySignInResult = SignInResult(
      isSignedIn: true,
      nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
    );

    test('ログインに成功し、状態が isAuthenticated = true になること', () async {
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(mockAuthRepository.signIn(username: testEmail, password: testPassword))
          .thenAnswer((_) async => dummySignInResult);
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
              userAttributeKey: AuthUserAttributeKey.preferredUsername,
              value: testUsername,
            ),
          ]);

      await viewModel.signIn(testEmail, testPassword);

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.isAuthenticated, true);
      expect(viewModel.state.username, testUsername);
      expect(viewModel.state.errorMessage, isNull);

      verify(mockAuthRepository.signOut()).called(1);
      verify(mockAuthRepository.signIn(username: testEmail, password: testPassword)).called(1);
    });

    test('AuthException が発生した場合、適切にエラー状態に変換されること', () async {
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(mockAuthRepository.signIn(username: testEmail, password: testPassword))
          .thenThrow(const AuthNotAuthorizedException('NotAuthorizedException'));

      await viewModel.signIn(testEmail, testPassword);

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.isAuthenticated, false);
      expect(viewModel.state.errorMessage, 'ログインに失敗しました: NotAuthorizedException');
    });

    test('予期せぬ Exception が発生した場合でも、汎用エラーとして安全に処理されること', () async {
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(mockAuthRepository.signIn(username: testEmail, password: testPassword))
          .thenThrow(Exception('ネットワークに接続されていません'));

      await viewModel.signIn(testEmail, testPassword);

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.isAuthenticated, false);
      expect(viewModel.state.errorMessage, '予期せぬエラーが発生しました: Exception: ネットワークに接続されていません');
    });

    test('事前の signOut 処理がエラーを吐いても、signIn 処理が継続されること', () async {
      when(mockAuthRepository.signOut()).thenThrow(Exception('すでにログアウトしています'));
      when(mockAuthRepository.signIn(username: testEmail, password: testPassword))
          .thenAnswer((_) async => dummySignInResult);
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => []);

      await viewModel.signIn(testEmail, testPassword);

      expect(viewModel.state.isAuthenticated, true);
      expect(viewModel.state.username, testEmail); 
      verify(mockAuthRepository.signIn(username: testEmail, password: testPassword)).called(1);
    });
  });
}
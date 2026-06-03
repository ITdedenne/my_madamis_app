import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/confirmation_viewmodel.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';
import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late SignInUseCase signInUseCase;
  late ConfirmationViewModel viewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    signInUseCase = SignInUseCase(mockAuthRepository);
    viewModel = ConfirmationViewModel(mockAuthRepository, signInUseCase);
  });

  group('ConfirmationViewModel Tests', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testCode = '123456';
    const testUsername = 'test_user';

    test('確認コードが正しく、認証と自動ログインに成功した場合、処理が完了すること', () async {
      when(mockAuthRepository.confirmSignUp(
              username: testEmail, confirmationCode: testCode))
          .thenAnswer((_) async => const SignUpResult(
                isSignUpComplete: true,
                nextStep: AuthNextSignUpStep(signUpStep: AuthSignUpStep.done),
              ));
              
      when(mockAuthRepository.signIn(username: testEmail, password: testPassword))
          .thenAnswer((_) async => const SignInResult(
                isSignedIn: true,
                nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
              ));
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
              userAttributeKey: AuthUserAttributeKey.preferredUsername,
              value: testUsername,
            ),
          ]);

      await viewModel.confirmSignUp(
          email: testEmail, password: testPassword, confirmationCode: testCode);

      expect(viewModel.state.status, ConfirmationStatus.success);
      expect(viewModel.state.errorMessage, isNull);
      expect(viewModel.state.authenticatedUsername, testUsername);
      
      verify(mockAuthRepository.confirmSignUp(
              username: testEmail, confirmationCode: testCode))
          .called(1);
    });

    test('確認コードが間違っていた場合、エラー状態になること', () async {
      when(mockAuthRepository.confirmSignUp(
              username: testEmail, confirmationCode: '000000'))
          .thenThrow(Exception('CodeMismatchException: Invalid code'));

      await viewModel.confirmSignUp(
          email: testEmail, password: testPassword, confirmationCode: '000000');

      expect(viewModel.state.status, ConfirmationStatus.error);
      expect(viewModel.state.errorMessage, contains('Invalid code'));
    });

    test('処理中は status が loading になること', () async {

      when(mockAuthRepository.confirmSignUp(
              username: testEmail, confirmationCode: testCode))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const SignUpResult(
          isSignUpComplete: true,
          nextStep: AuthNextSignUpStep(signUpStep: AuthSignUpStep.done),
        );
      });
      when(mockAuthRepository.signIn(username: testEmail, password: testPassword))
          .thenAnswer((_) async => const SignInResult(
                isSignedIn: true,
                nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
              ));
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => []);

      final future = viewModel.confirmSignUp(
          email: testEmail, password: testPassword, confirmationCode: testCode);
      
      expect(viewModel.state.status, ConfirmationStatus.loading);

      await future;

      expect(viewModel.state.status, ConfirmationStatus.success);
    });
  });
}
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late SignInUseCase signInUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    signInUseCase = SignInUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUsername = 'test_user';

  test('サインインに成功した場合、ユーザー名を返すこと', () async {
    when(mockAuthRepository.signIn(username: tEmail, password: tPassword))
        .thenAnswer((_) async => const SignInResult(
              isSignedIn: true,
              nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
            ));
    when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
          const AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.preferredUsername,
            value: tUsername,
          ),
        ]);

    final result = await signInUseCase.call(tEmail, tPassword);

    expect(result, tUsername);
    verify(mockAuthRepository.signIn(username: tEmail, password: tPassword)).called(1);
    verify(mockAuthRepository.getCurrentUserAttributes()).called(1);
  });

  test('メールアドレスが空の場合、例外をスローすること', () async {
    expect(() => signInUseCase.call('', tPassword), throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signIn(username: anyNamed('username'), password: anyNamed('password')));
  });

  test('パスワードが空の場合、例外をスローすること', () async {
    expect(() => signInUseCase.call(tEmail, ''), throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signIn(username: anyNamed('username'), password: anyNamed('password')));
  });

  test('認証に失敗した場合（NotAuthorizedException）、例外をそのままスローすること', () async {
    when(mockAuthRepository.signIn(username: tEmail, password: tPassword))
        .thenThrow(const AuthNotAuthorizedException('Not authorized'));

    expect(() => signInUseCase.call(tEmail, tPassword), throwsA(isA<AuthNotAuthorizedException>()));
  });

  test('ユーザーが存在しない場合（UserNotFoundException）、例外をそのままスローすること', () async {
    when(mockAuthRepository.signIn(username: tEmail, password: tPassword))
        .thenThrow(const UserNotFoundException('User not found'));

    expect(() => signInUseCase.call(tEmail, tPassword), throwsA(isA<UserNotFoundException>()));
  });
}
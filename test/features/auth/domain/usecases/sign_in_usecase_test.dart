import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

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

  test('正常なサインイン後、ユーザー名を返すこと', () async {
    // Arrange
    when(mockAuthRepository.signIn(username: anyNamed('username'), password: anyNamed('password')))
        .thenAnswer((_) async => const SignInResult(isSignedIn: true, nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done)));
    when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
          const AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.preferredUsername,
            value: tUsername,
          ),
        ]);

    // Act
    final result = await signInUseCase.call(tEmail, tPassword);

    // Assert
    expect(result, tUsername);
    verify(mockAuthRepository.signIn(username: tEmail, password: tPassword));
    verify(mockAuthRepository.getCurrentUserAttributes());
  });

  test('メールアドレスが空の場合、例外をスローすること', () async {
    // Act & Assert
    expect(() => signInUseCase.call('', tPassword), throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signIn(username: anyNamed('username'), password: anyNamed('password')));
  });
}
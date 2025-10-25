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

  test('サインインに成功した場合、ユーザー名を返すこと', () async {
    // Arrange: 振る舞いを定義
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

    // Act: テスト対象のメソッドを実行
    final result = await signInUseCase.call(tEmail, tPassword);

    // Assert 結果を検証
    expect(result, tUsername);
    verify(mockAuthRepository.signIn(username: tEmail, password: tPassword)).called(1);
    verify(mockAuthRepository.getCurrentUserAttributes()).called(1);
  });

  test('メールアドレスが空の場合、例外をスローすること', () async {
    // Act & Assert
    expect(() => signInUseCase.call('', tPassword), throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signIn(username: anyNamed('username'), password: anyNamed('password')));
  });

  test('パスワードが空の場合、例外をスローすること', () async {
    // Act & Assert
    expect(() => signInUseCase.call(tEmail, ''), throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signIn(username: anyNamed('username'), password: anyNamed('password')));
  });
}
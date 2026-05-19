import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:my_madamis_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import '../../../../mocks/mocks.mocks.dart';

// ignore: must_be_immutable
class MockUserProfile extends Mock implements UserProfile {
  @override
  final String username;
  MockUserProfile({required this.username});
}

void main() {
  late SignUpUseCase signUpUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    signUpUseCase = SignUpUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUsername = 'test_user';
  final tProfile = MockUserProfile(username: tUsername);

  test('サインアップリポジトリが正しい引数で呼び出されること', () async {
    when(mockAuthRepository.signUp(
            email: tEmail, password: tPassword, username: tUsername))
        .thenAnswer((_) async => const SignUpResult(
              isSignUpComplete: false,
              nextStep: AuthNextSignUpStep(
                  signUpStep: AuthSignUpStep.confirmSignUp),
            ));

    await signUpUseCase.call(
      email: tEmail,
      password: tPassword,
      profile: tProfile,
    );

    verify(mockAuthRepository.signUp(
            email: tEmail, password: tPassword, username: tUsername))
        .called(1);
  });

  test('既に登録済みのメールアドレスの場合、例外をスローすること', () async {
    when(mockAuthRepository.signUp(
            email: tEmail, password: tPassword, username: tUsername))
        .thenThrow(Exception('UsernameExistsException'));

    expect(
        () => signUpUseCase.call(
              email: tEmail,
              password: tPassword,
              profile: tProfile,
            ),
        throwsA(isA<Exception>()));
  });

  test('メールアドレスが空の場合、例外をスローすること', () async {
    expect(
        () => signUpUseCase.call(
              email: '',
              password: tPassword,
              profile: tProfile,
            ),
        throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        username: anyNamed('username')));
  });

  test('パスワードが空の場合、例外をスローすること', () async {
    expect(
        () => signUpUseCase.call(
              email: tEmail,
              password: '',
              profile: tProfile,
            ),
        throwsA(isA<Exception>()));
    verifyNever(mockAuthRepository.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        username: anyNamed('username')));
  });
}
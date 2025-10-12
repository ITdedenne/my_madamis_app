import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LoginViewModel Tests', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password';
    const tUsername = 'test_user';

    test('signInが成功した場合、isAuthenticatedがtrueになること', () async {
      // Arrange
      when(mockAuthRepository.signOut()).thenAnswer((_) async {}); // ログイン前のサインアウト処理
      when(mockAuthRepository.signIn(username: tEmail, password: tPassword))
          .thenAnswer((_) async => const SignInResult(isSignedIn: true, nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done)));
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: tUsername)
          ]);

      // Act
      await container.read(loginViewModelProvider.notifier).signIn(tEmail, tPassword);
      final state = container.read(loginViewModelProvider);

      // Assert
      expect(state.isAuthenticated, isTrue);
      expect(state.username, tUsername);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('signInが失敗した場合(UserNotFoundException)、errorMessageが設定されること', () async {
      // Arrange
      const exception = UserNotFoundException('User does not exist.');
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(mockAuthRepository.signIn(username: tEmail, password: tPassword))
          .thenThrow(exception);

      // Act
      await container.read(loginViewModelProvider.notifier).signIn(tEmail, tPassword);
      final state = container.read(loginViewModelProvider);

      // Assert
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });
  });
}
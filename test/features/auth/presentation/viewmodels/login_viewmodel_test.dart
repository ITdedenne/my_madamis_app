import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../mocks/mocks.g.dart';
import 'package:my_madamis_app/providers.dart';

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

    test('signIn 成功時、isAuthenticated が true になるべき', () async {
      // Arrange
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
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
    });

    test('signIn 失敗時(AuthException)、errorMessage が設定されるべき', () async {
      // Arrange
      final exception = AuthException('ログインに失敗しました');
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
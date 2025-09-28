// ファイルパス: test/features/auth/presentation/notifiers/auth_state_notifier_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockResetPasswordResult mockResetPasswordResult;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockResetPasswordResult = MockResetPasswordResult();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthStateNotifier Unit Tests', () {
    test('[NOTIFIER-001] signIn - 成功時にauthenticated状態とユーザー名が設定される', () async {
      // --- ここから修正 ---
      when(mockAuthRepository.signIn(
        username: 'test@example.com',
        password: 'password',
      )).thenAnswer((_) async => const SignInResult(
            isSignedIn: true,
            nextStep: AuthNextSignInStep(signInStep: AuthSignInStep.done),
          ));
      
      when(mockAuthRepository.fetchUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: 'test user')
          ]);
      // --- ここまで修正 ---

      final notifier = container.read(authStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          // --- ここから修正 ---
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.username, 'username', 'test user'),
          // --- ここまで修正 ---
        ]),
      );

      await notifier.signIn('test@example.com', 'password');
    });

    test('[NOTIFIER-002] signIn - 失敗時にerror状態になる', () async {
      when(mockAuthRepository.signIn(
        username: 'test@example.com',
        password: 'wrong_password',
      )).thenThrow(const NotAuthorizedServiceException(
           'Incorrect username or password.'));

      final notifier = container.read(authStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ]),
      );

      await notifier.signIn('test@example.com', 'wrong_password');
    });

    test('[NOTIFIER-003] resetPassword - 成功時にpasswordResetRequired状態になる',
        () async {
      const mockResetPasswordStep = ResetPasswordStep(
        updateStep: AuthResetPasswordStep.confirmResetPasswordWithCode,
      );
      when(mockResetPasswordResult.nextStep).thenReturn(mockResetPasswordStep);
      when(mockResetPasswordResult.isPasswordReset).thenReturn(false);

      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => mockResetPasswordResult);

      final notifier = container.read(authStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having(
              (s) => s.status, 'status', AuthStatus.passwordResetRequired),
        ]),
      );

      await notifier.resetPassword('test@example.com');
    });

    test('[NOTIFIER-004] confirmResetPassword - 成功時にpasswordResetSuccess状態になる',
        () async {
      when(mockAuthRepository.confirmResetPassword(
        username: anyNamed('username'),
        newPassword: anyNamed('newPassword'),
        confirmationCode: anyNamed('confirmationCode'),
      )).thenAnswer((_) async {});

      final notifier = container.read(authStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>().having(
              (s) => s.status, 'status', AuthStatus.passwordResetSuccess),
        ]),
      );

      await notifier.confirmResetPassword(
        username: 'test@example.com',
        newPassword: 'newPassword123',
        confirmationCode: '123456',
      );
    });

    test('[NOTIFIER-005] confirmResetPassword - コード間違いでerror状態になる', () async {
      when(mockAuthRepository.confirmResetPassword(
        username: anyNamed('username'),
        newPassword: anyNamed('newPassword'),
        confirmationCode: anyNamed('confirmationCode'),
      )).thenThrow(const CodeMismatchException( 'Invalid code'));

      final notifier = container.read(authStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.error)
              .having((s) => s.errorMessage, 'errorMessage',
                  '認証コードが間違っています。'),
        ]),
      );

      await notifier.confirmResetPassword(
        username: 'test@example.com',
        newPassword: 'newPassword123',
        confirmationCode: 'wrong-code',
      );
    });
  });
 group('Email Update', () {
      const newEmail = 'new@example.com';
      const confirmationCode = '123456';

      test('[NOTIFIER-006] updateEmail - 成功時にconfirmationRequiredForUpdate状態になる',
          () async {
        when(mockAuthRepository.updateEmail(newEmail)).thenAnswer((_) async =>
            const UpdateUserAttributeResult(
                isUpdated: false,
                nextStep: AuthNextUpdateAttributeStep(
                    updateAttributeStep:
                        AuthUpdateAttributeStep.confirmAttributeWithCode)));

        final notifier = container.read(authStateNotifierProvider.notifier);

        expect(
          notifier.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.loading),
            isA<AuthState>()
                .having((s) => s.status, 'status',
                    AuthStatus.confirmationRequiredForUpdate)
                .having((s) => s.usernameForConfirmation,
                    'usernameForConfirmation', newEmail),
          ]),
        );

        await notifier.updateEmail(newEmail);
      });

      test('[NOTIFIER-007] updateEmail - 失敗時にerror状態になる', () async {
        final exception = Exception('Update failed');
        when(mockAuthRepository.updateEmail(newEmail)).thenThrow(exception);

        final notifier = container.read(authStateNotifierProvider.notifier);

        expect(
          notifier.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.loading),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.error)
                .having((s) => s.errorMessage, 'errorMessage', isNotNull),
          ]),
        );

        await notifier.updateEmail(newEmail);
      });

      test('[NOTIFIER-008] confirmUpdateEmail - 成功時にemailUpdateSuccess状態になる',
          () async {
        when(mockAuthRepository.confirmUpdateEmail(confirmationCode))
            .thenAnswer((_) async {});

        final notifier = container.read(authStateNotifierProvider.notifier);

        expect(
          notifier.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.loading),
            isA<AuthState>().having(
                (s) => s.status, 'status', AuthStatus.emailUpdateSuccess),
          ]),
        );

        await notifier.confirmUpdateEmail(confirmationCode);
      });

      test('[NOTIFIER-009] confirmUpdateEmail - 失敗時にerror状態になる', () async {
        final exception = Exception('Confirmation failed');
        when(mockAuthRepository.confirmUpdateEmail(confirmationCode))
            .thenThrow(exception);

        final notifier = container.read(authStateNotifierProvider.notifier);

        expect(
          notifier.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.loading),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.error)
                .having((s) => s.errorMessage, 'errorMessage', isNotNull),
          ]),
        );

        await notifier.confirmUpdateEmail(confirmationCode);
      });
    });

    group('Password Update', () {
      const oldPassword = 'oldPassword123';
      const newPassword = 'newPassword123';

      test('[NOTIFIER-010] updatePassword - 成功時にpasswordUpdateSuccess状態になる',
          () async {
        when(mockAuthRepository.updatePassword(
                oldPassword: oldPassword, newPassword: newPassword))
            .thenAnswer((_) async {});

        final notifier = container.read(authStateNotifierProvider.notifier);

        expect(
          notifier.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.loading),
            isA<AuthState>().having(
                (s) => s.status, 'status', AuthStatus.passwordUpdateSuccess),
          ]),
        );

        await notifier.updatePassword(
            oldPassword: oldPassword, newPassword: newPassword);
      });

      test('[NOTIFIER-011] updatePassword - 失敗時にerror状態になる', () async {
        final exception = Exception('Update failed');
        when(mockAuthRepository.updatePassword(
                oldPassword: oldPassword, newPassword: newPassword))
            .thenThrow(exception);

        final notifier = container.read(authStateNotifierProvider.notifier);

        expect(
          notifier.stream,
          emitsInOrder([
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.loading),
            isA<AuthState>()
                .having((s) => s.status, 'status', AuthStatus.error)
                .having((s) => s.errorMessage, 'errorMessage', isNotNull),
          ]),
        );

        await notifier.updatePassword(
            oldPassword: oldPassword, newPassword: newPassword);
      });
    });

}
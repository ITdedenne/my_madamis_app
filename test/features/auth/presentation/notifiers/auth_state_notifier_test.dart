import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../mocks/mocks.g.dart'; // 生成されたモック
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

  group('AuthStateNotifier Tests', () {
    test('初期状態では unauthenticated であるべき (checkCurrentUserが失敗した場合)', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenThrow(Exception());
      
      // Act
      // Notifierの初期化で_checkCurrentUserが呼ばれるのを待つ
      await container.read(authStateNotifierProvider.notifier);
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('現在のユーザーが取得できた場合、authenticated 状態になるべき', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: 'test_user')
          ]);
          
      // Act
      // Notifierを初期化
      final notifier = container.read(authStateNotifierProvider.notifier);
      // 非同期処理の完了を待つ
      await Future.delayed(Duration.zero);
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.authenticated);
      expect(state.username, 'test_user');
    });

    test('signOut を呼ぶと unauthenticated 状態になるべき', () async {
      // Arrange
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
      
      // Act
      await container.read(authStateNotifierProvider.notifier).signOut();
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('resetPassword 成功時、passwordResetRequired 状態になるべき', () async {
      // Arrange
      when(mockAuthRepository.resetPassword(username: 'test@example.com'))
          .thenAnswer((_) async {});
      
      // Act
      await container.read(authStateNotifierProvider.notifier).resetPassword('test@example.com');
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.passwordResetRequired);
    });

    test('confirmPasswordReset 成功時、unauthenticated 状態になるべき', () async {
      // Arrange
      when(mockAuthRepository.confirmResetPassword(
        username: anyNamed('username'),
        newPassword: anyNamed('newPassword'),
        confirmationCode: anyNamed('confirmationCode'),
      )).thenAnswer((_) async {});
      
      // Act
      await container.read(authStateNotifierProvider.notifier)
          .confirmPasswordReset('user', 'new_pass', '123456');
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.unauthenticated);
    });
  });
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  // 各テストの前に呼ばれる
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // ProviderContainerを初期化し、authRepositoryProviderをモックで上書き
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
    );
  });

  // 各テストの後に呼ばれる
  tearDown(() {
    container.dispose();
  });

  group('AuthStateNotifier Tests', () {
    test('初期化時にユーザー取得が成功した場合、authenticated状態になること', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: 'test_user')
          ]);

      // Act
      // Notifierをreadして初期化処理を待つ
      container.read(authStateNotifierProvider.notifier);
      final state = container.read(authStateNotifierProvider);

      // Assert
      expect(state.status, AuthStatus.authenticated);
      expect(state.username, 'test_user');
    });

    test('初期化時にユーザー取得が失敗した場合、unauthenticated状態になること', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenThrow(Exception('No user'));

      // Act
      container.read(authStateNotifierProvider.notifier);
      final state = container.read(authStateNotifierProvider);

      // Assert
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('signOutを呼ぶとunauthenticated状態になること', () async {
      // Arrange
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
       // 初期状態をauthenticatedにする
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: 'test_user')
          ]);
      container.read(authStateNotifierProvider.notifier);


      // Act
      await container.read(authStateNotifierProvider.notifier).signOut();
      final state = container.read(authStateNotifierProvider);

      // Assert
      expect(state.status, AuthStatus.unauthenticated);
      verify(mockAuthRepository.signOut()).called(1);
    });
  });
}
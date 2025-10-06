import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../mocks/mocks.mocks.dart';

// late初期化を安全に行うためのヘルパー
Future<ProviderContainer> createContainer(MockAuthRepository mockRepo) async {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
  );
  // Notifierの初期化(_checkCurrentUser)が終わるのを待つ
  await container.read(authStateNotifierProvider.notifier);
  return container;
}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthStateNotifier Tests', () {
    test('初期化時にユーザー取得が失敗した場合、unauthenticated状態になること', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenThrow(Exception('No user'));
      
      // Act
      final container = await createContainer(mockAuthRepository);
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('初期化時にユーザー取得が成功した場合、authenticated状態になること', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
        const AuthUserAttribute(userAttributeKey: AuthUserAttributeKey.preferredUsername, value: 'test_user')
      ]);
          
      // Act
      final container = await createContainer(mockAuthRepository);
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.authenticated);
      expect(state.username, 'test_user');
    });

    test('signOutを呼ぶとunauthenticated状態になること', () async {
       // Arrange
      when(mockAuthRepository.getCurrentUserAttributes()).thenThrow(Exception()); // 初期状態をunauthenticatedにする
      when(mockAuthRepository.signOut()).thenAnswer((_) async {});
      
      // Act
      final container = await createContainer(mockAuthRepository);
      await container.read(authStateNotifierProvider.notifier).signOut();
      final state = container.read(authStateNotifierProvider);
      
      // Assert
      expect(state.status, AuthStatus.unauthenticated);
      verify(mockAuthRepository.signOut()).called(1);
    });
  });
}
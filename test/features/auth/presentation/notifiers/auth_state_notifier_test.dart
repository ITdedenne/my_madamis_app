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

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthStateNotifier Tests', () {
    testWidgets('初期化時にユーザー取得が成功した場合、authenticated状態になること', (tester) async {

      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: 'test_user')
          ]);

 
      container.read(authStateNotifierProvider.notifier);

      await tester.pumpAndSettle();

      final state = container.read(authStateNotifierProvider);

      expect(state.status, AuthStatus.authenticated);
      expect(state.username, 'test_user');
    });

    testWidgets('初期化時にユーザー取得が失敗した場合、unauthenticated状態になること', (tester) async {

      when(mockAuthRepository.getCurrentUserAttributes())
          .thenThrow(Exception('No user'));

      container.read(authStateNotifierProvider.notifier);
      await tester.pumpAndSettle();

      final state = container.read(authStateNotifierProvider);

      expect(state.status, AuthStatus.unauthenticated);
    });

    testWidgets('signOutを呼ぶとunauthenticated状態になること', (tester) async {

      when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => [
            const AuthUserAttribute(
                userAttributeKey: AuthUserAttributeKey.preferredUsername,
                value: 'test_user')
          ]);
      container.read(authStateNotifierProvider.notifier);
      await tester.pumpAndSettle();

      when(mockAuthRepository.signOut()).thenAnswer((_) async {});

      await container.read(authStateNotifierProvider.notifier).signOut();
      final state = container.read(authStateNotifierProvider);

      expect(state.status, AuthStatus.unauthenticated);
      verify(mockAuthRepository.signOut()).called(1);
    });
  });
}
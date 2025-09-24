// ファイルパス: test/features/profile/presentation/notifiers/profile_state_notifier_test.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/data/auth_repository.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/presentation/notifiers/profile_state_notifier.dart';

import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    
    final dummyAuthNotifier = AuthStateNotifier(mockAuthRepository);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        // .overrideWithValue(notifier) を .overrideWith((ref) => notifier) の形式に修正
        authStateNotifierProvider.overrideWith(
          (ref) => dummyAuthNotifier,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProfileStateNotifier Unit Tests', () {
    const mockUsername = 'test_user';
    const mockBio = 'Hello, this is a test bio.';
    final mockAttributes = {
      AuthUserAttributeKey.preferredUsername: mockUsername,
      const CognitoUserAttributeKey.custom('bio'): mockBio,
    };

    test('[PROFILE-NOTIFIER-001] loadCurrentUser - 成功時にloaded状態になり、ユーザー情報が設定される', () async {
      when(mockAuthRepository.fetchCurrentUserAttributes())
          .thenAnswer((_) async => mockAttributes);

      final notifier = container.read(profileStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.loading),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.loaded)
              .having((s) => s.username, 'username', mockUsername)
              .having((s) => s.bio, 'bio', mockBio),
        ]),
      );

      await notifier.loadCurrentUser();
    });

    test('[PROFILE-NOTIFIER-002] loadCurrentUser - 失敗時にerror状態になる', () async {
      final exception = Exception('Failed to fetch user attributes');
      when(mockAuthRepository.fetchCurrentUserAttributes()).thenThrow(exception);

      final notifier = container.read(profileStateNotifierProvider.notifier);

      expect(
        notifier.stream,
        emitsInOrder([
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.loading),
          isA<ProfileState>()
              .having((s) => s.status, 'status', ProfileStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ]),
      );
      
      await notifier.loadCurrentUser();
    });

    test('[PROFILE-NOTIFIER-003] updateProfile - 成功時にrepositoryが呼ばれ、状態が更新される', () async {
      const newUsername = 'new_username';
      const newBio = 'new_bio';
      const newtwitterId = 'new_twitterId';

      when(mockAuthRepository.updateUserAttributes(username: newUsername, bio: newBio,twitterId: newtwitterId))
          .thenAnswer((_) async {});

      final notifier = container.read(profileStateNotifierProvider.notifier);
      final success = await notifier.updateProfile(username: newUsername, bio: newBio,twitterId: newtwitterId);

      expect(success, isTrue);
      verify(mockAuthRepository.updateUserAttributes(username: newUsername, bio: newBio,twitterId: newtwitterId)).called(1);
      
      final state = container.read(profileStateNotifierProvider);
      expect(state.username, newUsername);
      expect(state.bio, newBio);
      expect(state.updateStatus, UpdateStatus.success);
    });

    test('[PROFILE-NOTIFIER-004] updateProfile - 失敗時にerror状態になり、falseが返される', () async {
      const newUsername = 'new_username';
      const newBio = 'new_bio';
      const newtwitterId = 'new_twitterId';
      final exception = Exception('Failed to update profile');
      when(mockAuthRepository.updateUserAttributes(username: newUsername, bio: newBio,twitterId: newtwitterId))
          .thenThrow(exception);

      final notifier = container.read(profileStateNotifierProvider.notifier);
      final success = await notifier.updateProfile(username: newUsername, bio: newBio,twitterId: newtwitterId);

      expect(success, isFalse);

      final state = container.read(profileStateNotifierProvider);
      expect(state.updateStatus, UpdateStatus.error);
    });

    test('[PROFILE-NOTIFIER-005] resetUpdateStatus - updateStatusがinitialにリセットされる', () async {
      final notifier = container.read(profileStateNotifierProvider.notifier);

      // 状態をsuccessに設定
      notifier.state = notifier.state.copyWith(updateStatus: UpdateStatus.success);
      expect(container.read(profileStateNotifierProvider).updateStatus, UpdateStatus.success);

      // リセットを実行
      notifier.resetUpdateStatus();
      expect(container.read(profileStateNotifierProvider).updateStatus, UpdateStatus.initial);
    });
  });
}
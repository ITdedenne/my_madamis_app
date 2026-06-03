// ファイルパス: test/features/profile/presentation/viewmodels/profile_viewmodel_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockProfileRepository mockProfileRepository;
  late ProviderContainer container;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const tUserProfile = UserProfile(
    publicUserId: '123',
    username: 'test_user',
    bio: 'test bio',
  );

  group('ProfileViewModel', () {
    test('初期化時にプロフィール取得が成功し、stateがloadedになること', () async {
      when(mockProfileRepository.fetchUserProfile())
          .thenAnswer((_) async => tUserProfile);

      // ViewModelをインスタンス化（コンストラクタ内でloadUserProfileが呼ばれる想定）
      container.read(profileViewModelProvider.notifier);

      // 非同期の完了を待機
      await Future.delayed(Duration.zero);

      final state = container.read(profileViewModelProvider);
      expect(state.status, ProfileStatus.loaded);
      expect(state.profile, tUserProfile);
      verify(mockProfileRepository.fetchUserProfile()).called(1);
    });

    test('プロフィール取得に失敗した場合、stateがerrorになること', () async {
      when(mockProfileRepository.fetchUserProfile())
          .thenThrow(Exception('Failed to load'));

      container.read(profileViewModelProvider.notifier);
      await Future.delayed(Duration.zero);

      final state = container.read(profileViewModelProvider);
      expect(state.status, ProfileStatus.error);
      expect(state.errorMessage, isNotNull);
      verify(mockProfileRepository.fetchUserProfile()).called(1);
    });

    test('updateStateWithNewProfile呼び出しでStateが更新されること', () {
      const newProfile = UserProfile(
        publicUserId: '456',
        username: 'new_user',
        bio: 'new bio',
      );

      container
          .read(profileViewModelProvider.notifier)
          .updateStateWithNewProfile(newProfile);
      
      final state = container.read(profileViewModelProvider);
      expect(state.profile, newProfile);
    });
  });
}
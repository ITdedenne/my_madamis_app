// ファイルパス: test/features/profile/presentation/viewmodels/edit_profile_viewmodel_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

class FakeProfileViewModel extends StateNotifier<ProfileState>
    implements ProfileViewModel {
  FakeProfileViewModel(super.state);
  @override
  Future<void> loadUserProfile() async {}
  @override
  void updateStateWithNewProfile(UserProfile newProfile) {
    state = state.copyWith(profile: newProfile);
  }
}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  const tProfile = UserProfile(
    publicUserId: '1234567',
    username: 'new_user',
    bio: 'new_bio',
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        profileViewModelProvider
            .overrideWith((ref) => FakeProfileViewModel(ProfileState())),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('EditProfileViewModel', () {
    test('プロファイル更新が成功した場合、success状態となり関連ViewModelが更新されること', () async {
      when(mockProfileRepository.updateUserProfile(any)).thenAnswer((_) async {});
      when(mockAuthRepository.getCurrentUserAttributes())
          .thenAnswer((_) async => []);

      await container.read(editProfileViewModelProvider.notifier).updateProfile(
            publicUserId: tProfile.publicUserId,
            username: tProfile.username,
            bio: tProfile.bio,
            twitterId: tProfile.twitterId,
          );

      final state = container.read(editProfileViewModelProvider);
      expect(state.status, EditProfileStatus.success);

      // プロフィールとAuthの関連状態が更新されているか検証
      final profileState = container.read(profileViewModelProvider);
      expect(profileState.profile, tProfile);

      final authState = container.read(authStateNotifierProvider);
      expect(authState.username, tProfile.username);
    });

    test('プロファイル更新が失敗した場合、error状態になること', () async {
      when(mockProfileRepository.updateUserProfile(any))
          .thenThrow(Exception('Update failed'));

      await container.read(editProfileViewModelProvider.notifier).updateProfile(
            publicUserId: tProfile.publicUserId,
            username: tProfile.username,
            bio: tProfile.bio,
            twitterId: tProfile.twitterId,
          );

      final state = container.read(editProfileViewModelProvider);
      expect(state.status, EditProfileStatus.error);
      expect(state.errorMessage, isNotNull);
    });
  });
}
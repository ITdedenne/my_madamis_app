import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';


void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        // EditProfileViewModelが依存している他のProviderもここでoverrideする
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const username = 'new_user';
  const bio = 'new_bio';
  const twitterId = 'new_twitter';
  const tProfile = UserProfile(username: username, bio: bio, twitterId: twitterId);

  test('プロファイル更新が成功した場合、stateがsuccessになり、関連するViewModelが更新されること', () async {
    // Arrange
    when(mockProfileRepository.updateUserProfile(any)).thenAnswer((_) async {});
    // AuthStateNotifierの初期化をシミュレート
    when(mockAuthRepository.getCurrentUserAttributes()).thenAnswer((_) async => []);

    // Act
    await container
        .read(editProfileViewModelProvider.notifier)
        .updateProfile(username: username, bio: bio, twitterId: twitterId);

    // Assert
    final state = container.read(editProfileViewModelProvider);
    expect(state.status, EditProfileStatus.success);

    // 関連するViewModelが更新されたかどうかの検証
    final profileState = container.read(profileViewModelProvider);
    expect(profileState.profile, tProfile);

    final authState = container.read(authStateNotifierProvider);
    expect(authState.username, username);
  });

  test('プロファイル更新が失敗した場合、stateがerrorになること', () async {
    // Arrange
    final exception = Exception('Update failed');
    when(mockProfileRepository.updateUserProfile(any)).thenThrow(exception);

    // Act
    await container
        .read(editProfileViewModelProvider.notifier)
        .updateProfile(username: username, bio: bio, twitterId: twitterId);

    // Assert
    final state = container.read(editProfileViewModelProvider);
    expect(state.status, EditProfileStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
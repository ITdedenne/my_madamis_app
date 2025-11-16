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
// import '../pages/profile_page_test.dart'; // ★ 修正: 不要なインポートを削除

// ★ 修正: FakeProfileViewModelをトップレベルに移動
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

  // ★ 修正: tProfile のインスタンス化
  const tProfile = UserProfile(
    publicUserId: '1234567',
    username: 'new_user',
    bio: 'new_bio',
    twitterId: '', // twitterIdは空文字固定
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        // ★ 修正: editProfileViewModelが依存するprofileViewModelProviderをモック化
        profileViewModelProvider
            .overrideWith((ref) => FakeProfileViewModel(ProfileState())),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('プロファイル更新が成功した場合、stateがsuccessになり、関連するViewModelが更新されること', () async {
    // Arrange
    when(mockProfileRepository.updateUserProfile(any)).thenAnswer((_) async {});
    when(mockAuthRepository.getCurrentUserAttributes())
        .thenAnswer((_) async => []);

    // Act
    // ★ 修正: updateProfile の呼び出し
    await container
        .read(editProfileViewModelProvider.notifier)
        .updateProfile(
          publicUserId: tProfile.publicUserId, // ★ 修正
          username: tProfile.username,
          bio: tProfile.bio,
          twitterId: tProfile.twitterId,
        );

    // Assert
    final state = container.read(editProfileViewModelProvider);
    expect(state.status, EditProfileStatus.success);

    // 関連するViewModelが更新されたかどうかの検証
    final profileState = container.read(profileViewModelProvider);
    expect(profileState.profile, tProfile);

    final authState = container.read(authStateNotifierProvider);
    expect(authState.username, tProfile.username);
  });

  test('プロファイル更新が失敗した場合、stateがerrorになること', () async {
    // Arrange
    final exception = Exception('Update failed');
    when(mockProfileRepository.updateUserProfile(any)).thenThrow(exception);

    // Act
    // ★ 修正: updateProfile の呼び出し
    await container
        .read(editProfileViewModelProvider.notifier)
        .updateProfile(
          publicUserId: tProfile.publicUserId, // ★ 修正
          username: tProfile.username,
          bio: tProfile.bio,
          twitterId: tProfile.twitterId,
        );

    // Assert
    final state = container.read(editProfileViewModelProvider);
    expect(state.status, EditProfileStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
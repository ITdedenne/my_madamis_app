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

  // 各テストの前に実行
  setUp(() {
    mockProfileRepository = MockProfileRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
      ],
    );
  });

  // 各テストの後に実行
  tearDown(() {
    container.dispose();
  });

  const tUserProfile = UserProfile(username: 'test_user', bio: 'test bio');

  // ▼▼▼ このテストを修正します ▼▼▼
  test('初期化時にloadUserProfileが呼ばれ、成功時にstateがloadedになること', () async {
    // Arrange
    when(mockProfileRepository.fetchUserProfile())
        .thenAnswer((_) async => tUserProfile);

    // Act
    // ViewModelをインスタンス化します。これによりコンストラクタ内のloadUserProfileが自動で実行されます。
    container.read(profileViewModelProvider.notifier);

    // 非同期処理が完了するのを待ちます。
    // `viewModel.state` をチェックする前に、マイクロタスクを処理させるための短い待機を入れます。
    await Future.delayed(Duration.zero);

    // Assert
    final state = container.read(profileViewModelProvider);
    expect(state.status, ProfileStatus.loaded);
    expect(state.profile, tUserProfile);
    
    // `fetchUserProfile` がコンストラクタから1回だけ呼ばれたことを確認します。
    verify(mockProfileRepository.fetchUserProfile()).called(1);
  });
  // ▲▲▲ 修正完了 ▲▲▲

  test('loadUserProfileが失敗した場合、stateがerrorになること', () async {
    // Arrange
    final exception = Exception('Failed to load');
    when(mockProfileRepository.fetchUserProfile()).thenThrow(exception);

    // Act
    // このテストも同様に、明示的な呼び出しは不要です。
    container.read(profileViewModelProvider.notifier);
    await Future.delayed(Duration.zero);
    
    final state = container.read(profileViewModelProvider);

    // Assert
    expect(state.status, ProfileStatus.error);
    expect(state.errorMessage, isNotNull);
    verify(mockProfileRepository.fetchUserProfile()).called(1);
  });

  test('updateStateWithNewProfileメソッドでStateが直接更新されること', () {
    // Arrange
    const newProfile = UserProfile(username: 'new_user', bio: 'new bio');

    // Act
    container
        .read(profileViewModelProvider.notifier)
        .updateStateWithNewProfile(newProfile);
    final state = container.read(profileViewModelProvider);

    // Assert
    expect(state.profile, newProfile);
  });
}
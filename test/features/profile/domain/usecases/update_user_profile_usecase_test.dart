// ファイルパス: test/features/profile/domain/usecases/update_user_profile_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/usecases/update_user_profile_usecase.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late UpdateUserProfileUseCase useCase;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    useCase = UpdateUserProfileUseCase(mockProfileRepository);
  });

  const tUserProfile = UserProfile(
    publicUserId: '1234567', // ★ 追加
    username: 'updated_user',
    bio: 'Updated bio.',
    twitterId: 'updated_twitter',
  );

  test('有効なUserProfileでリポジトリのupdateUserProfileが呼ばれること', () async {
    // Arrange
    when(mockProfileRepository.updateUserProfile(any))
        .thenAnswer((_) async {});

    // Act
    await useCase(tUserProfile);

    // Assert
    verify(mockProfileRepository.updateUserProfile(tUserProfile));
    verifyNoMoreInteractions(mockProfileRepository);
  });

  group('バリデーション', () {
    test('ユーザー名が空の場合、例外をスローすること', () {
      // Arrange
      final profileWithEmptyUsername =
          tUserProfile.copyWith(username: '');

      // Act & Assert
      expect(() => useCase(profileWithEmptyUsername), throwsA(isA<Exception>()));
      verifyNever(mockProfileRepository.updateUserProfile(any));
    });

    test('ユーザー名がスペースのみの場合、例外をスローすること', () {
      // Arrange
      final profileWithWhitespaceUsername =
          tUserProfile.copyWith(username: '   ');

      // Act & Assert
      expect(() => useCase(profileWithWhitespaceUsername), throwsA(isA<Exception>()));
      verifyNever(mockProfileRepository.updateUserProfile(any));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/profile/domain/entities/user_profile.dart';
import 'package:my_madamis_app/features/profile/domain/usecases/get_user_profile_usecase.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late GetUserProfileUseCase useCase;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    useCase = GetUserProfileUseCase(mockProfileRepository);
  });

  const tUserProfile = UserProfile(
    username: 'test_user',
    bio: 'This is a test bio.',
    twitterId: 'test_twitter',
  );

  test('リポジトリから正常にUserProfileが返されること', () async {
    // Arrange
    when(mockProfileRepository.fetchUserProfile())
        .thenAnswer((_) async => tUserProfile);

    // Act
    final result = await useCase();

    // Assert
    expect(result, tUserProfile);
    verify(mockProfileRepository.fetchUserProfile());
    verifyNoMoreInteractions(mockProfileRepository);
  });

  test('リポジトリが例外をスローした場合、その例外が呼び出し元に伝播すること', () async {
    // Arrange
    final exception = Exception('Failed to fetch profile');
    when(mockProfileRepository.fetchUserProfile()).thenThrow(exception);

    // Act & Assert
    expect(() => useCase(), throwsA(isA<Exception>()));
    verify(mockProfileRepository.fetchUserProfile());
    verifyNoMoreInteractions(mockProfileRepository);
  });
}
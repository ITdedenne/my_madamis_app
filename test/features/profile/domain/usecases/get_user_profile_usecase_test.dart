// ファイルパス: test/features/profile/domain/usecases/get_user_profile_usecase_test.dart

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
    publicUserId: '1234567',
    username: 'test_user',
    bio: 'This is a test bio.',
    twitterId: 'test_twitter',
  );

  test('リポジトリから正常にUserProfileが返されること', () async {

    when(mockProfileRepository.fetchUserProfile())
        .thenAnswer((_) async => tUserProfile);

    final result = await useCase();

    expect(result, tUserProfile);
    verify(mockProfileRepository.fetchUserProfile());
    verifyNoMoreInteractions(mockProfileRepository);
  });

  test('リポジトリが例外をスローした場合、その例外が呼び出し元に伝播すること', () async {

    final exception = Exception('Failed to fetch profile');
    when(mockProfileRepository.fetchUserProfile()).thenThrow(exception);

    expect(() => useCase(), throwsA(isA<Exception>()));
    verify(mockProfileRepository.fetchUserProfile());
    verifyNoMoreInteractions(mockProfileRepository);
  });
}
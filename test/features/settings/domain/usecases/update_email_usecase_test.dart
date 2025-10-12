import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/settings/domain/usecases/update_email_usecase.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late UpdateEmailUseCase useCase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    useCase = UpdateEmailUseCase(mockSettingsRepository);
  });

  const validEmail = 'new@example.com';

  test('有効なメールアドレスの場合、リポジトリのupdateEmailが呼ばれること', () async {
    // Arrange
    when(mockSettingsRepository.updateEmail(any)).thenAnswer((_) async {});

    // Act
    await useCase(validEmail);

    // Assert
    verify(mockSettingsRepository.updateEmail(validEmail)).called(1);
  });

  group('バリデーション', () {
    test('メールアドレスが空の場合、例外をスローすること', () {
      // Act & Assert
      expect(() => useCase(''), throwsA(isA<Exception>()));
      verifyNever(mockSettingsRepository.updateEmail(any));
    });

    test('メールアドレスの形式が不正な場合、例外をスローすること', () {
      // Act & Assert
      expect(() => useCase('invalid-email'), throwsA(isA<Exception>()));
      verifyNever(mockSettingsRepository.updateEmail(any));
    });
  });
}
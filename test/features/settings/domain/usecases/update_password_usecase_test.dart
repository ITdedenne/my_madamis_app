import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/settings/domain/usecases/update_password_usecase.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late UpdatePasswordUseCase useCase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    useCase = UpdatePasswordUseCase(mockSettingsRepository);
  });

  const oldPassword = 'oldPassword123';
  const newPassword = 'newPassword123';

  // 正常系テスト
  test('正常なパスワード変更時にはリポジトリのupdatePasswordが呼ばれること', () async {
    // Arrange
    when(mockSettingsRepository.updatePassword(
      oldPassword: anyNamed('oldPassword'),
      newPassword: anyNamed('newPassword'),
    )).thenAnswer((_) async {});

    // Act
    await useCase(oldPassword: oldPassword, newPassword: newPassword);

    // Assert
    verify(mockSettingsRepository.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    )).called(1);
  });

  // 異常系・エッジケースのテスト
  group('バリデーションとエッジケース', () {
    test('古いパスワードが空の場合、例外をスローすること', () async {
      // Act & Assert
      expect(
        () => useCase(oldPassword: '', newPassword: newPassword),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockSettingsRepository.updatePassword(
          oldPassword: anyNamed('oldPassword'),
          newPassword: anyNamed('newPassword')));
    });

    test('新しいパスワードが空の場合、例外をスローすること', () async {
      // Act & Assert
      expect(
        () => useCase(oldPassword: oldPassword, newPassword: ''),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockSettingsRepository.updatePassword(
          oldPassword: anyNamed('oldPassword'),
          newPassword: anyNamed('newPassword')));
    });

    test('新しいパスワードが8文字未満の場合、例外をスローすること', () async {
      // Act & Assert
      expect(
        () => useCase(oldPassword: oldPassword, newPassword: 'short'),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockSettingsRepository.updatePassword(
          oldPassword: anyNamed('oldPassword'),
          newPassword: anyNamed('newPassword')));
    });
  });
}
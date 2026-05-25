import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/update_password_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

void main() {
  late MockSettingsRepository mockSettingsRepository;
  late ProviderContainer container;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const oldPassword = 'oldPassword123';
  const newPassword = 'newPassword123';

  test('パスワード更新が成功した場合、stateがsuccessになること', () async {

    when(mockSettingsRepository.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    )).thenAnswer((_) async {});

    await container.read(updatePasswordViewModelProvider.notifier).updatePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );

    final state = container.read(updatePasswordViewModelProvider);
    expect(state.status, UpdatePasswordStatus.success);
  });

  test('パスワード更新が失敗した場合、stateがerrorになること', () async {

    final exception = Exception('更新失敗');
    when(mockSettingsRepository.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    )).thenThrow(exception);

    await container.read(updatePasswordViewModelProvider.notifier).updatePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );

    final state = container.read(updatePasswordViewModelProvider);
    expect(state.status, UpdatePasswordStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
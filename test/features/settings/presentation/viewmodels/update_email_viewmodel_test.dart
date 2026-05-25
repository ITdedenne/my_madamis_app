import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/update_email_viewmodel.dart';
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

  const newEmail = 'new@example.com';

  test('メールアドレス更新が成功した場合、stateがrequiresConfirmationになること', () async {

    when(mockSettingsRepository.updateEmail(newEmail)).thenAnswer((_) async {});

    await container.read(updateEmailViewModelProvider.notifier).updateEmail(newEmail);

    final state = container.read(updateEmailViewModelProvider);
    expect(state.status, UpdateEmailStatus.requiresConfirmation);
  });

  test('メールアドレス更新が失敗した場合、stateがerrorになること', () async {

    final exception = Exception('更新失敗');
    when(mockSettingsRepository.updateEmail(newEmail)).thenThrow(exception);

    await container.read(updateEmailViewModelProvider.notifier).updateEmail(newEmail);

    final state = container.read(updateEmailViewModelProvider);
    expect(state.status, UpdateEmailStatus.error);
    expect(state.errorMessage, isNotNull);
  });
}
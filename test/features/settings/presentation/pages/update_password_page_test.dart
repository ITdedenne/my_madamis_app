import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_password_page.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/update_password_viewmodel.dart';

// Mockクラス
class MockUpdatePasswordViewModel extends StateNotifier<UpdatePasswordState>
    with Mock
    implements UpdatePasswordViewModel {
  MockUpdatePasswordViewModel(super.state);

  @override
  Future<void> updatePassword(
      {required String oldPassword, required String newPassword}) {
    return super.noSuchMethod(
      Invocation.method(
          #updatePassword, [], {#oldPassword: oldPassword, #newPassword: newPassword}),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MockUpdatePasswordViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockUpdatePasswordViewModel(UpdatePasswordState());
  });

  testWidgets('フォーム入力後にボタンをタップするとupdatePasswordが呼ばれること', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updatePasswordViewModelProvider.overrideWith((ref) => mockViewModel),
        ],
        child: const MaterialApp(home: UpdatePasswordPage()),
      ),
    );

    const oldPassword = 'oldPassword123';
    const newPassword = 'newPassword123';

    // Act
    await tester.enterText(
        find.widgetWithText(TextFormField, '現在のパスワード'), oldPassword);
    await tester.enterText(
        find.widgetWithText(TextFormField, '新しいパスワード (8文字以上)'), newPassword);
    await tester.tap(find.widgetWithText(PrimaryButton, 'パスワードを変更'));

    // Assert
    verify(mockViewModel.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    )).called(1);
  });
}
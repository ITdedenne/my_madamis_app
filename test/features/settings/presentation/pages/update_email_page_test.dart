import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/update_email_page.dart';
import 'package:my_madamis_app/features/settings/presentation/viewmodels/update_email_viewmodel.dart';

class MockUpdateEmailViewModel extends StateNotifier<UpdateEmailState>
    with Mock
    implements UpdateEmailViewModel {
  MockUpdateEmailViewModel(super.state);

  @override
  Future<void> updateEmail(String newEmail) {
    return super.noSuchMethod(
      Invocation.method(#updateEmail, [newEmail]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MockUpdateEmailViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockUpdateEmailViewModel(UpdateEmailState());
  });

  testWidgets('フォーム入力後にボタンをタップするとupdateEmailが呼ばれること', (tester) async {

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateEmailViewModelProvider.overrideWith((ref) => mockViewModel),
        ],
        child: const MaterialApp(home: UpdateEmailPage()),
      ),
    );

    const newEmail = 'new@example.com';

    await tester.enterText(find.widgetWithText(TextFormField, '新しいメールアドレス'), newEmail);
    await tester.tap(find.widgetWithText(PrimaryButton, '確認コードを送信'));

    verify(mockViewModel.updateEmail(newEmail)).called(1);
  });

  testWidgets('不正な形式のメールアドレスでボタンをタップしてもupdateEmailが呼ばれないこと', (tester) async {

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateEmailViewModelProvider.overrideWith((ref) => mockViewModel),
        ],
        child: const MaterialApp(home: UpdateEmailPage()),
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, '新しいメールアドレス'), 'invalid-email');
    await tester.tap(find.widgetWithText(PrimaryButton, '確認コードを送信'));
    await tester.pump(); 

    expect(find.text('有効なメールアドレスを入力してください'), findsOneWidget);
    verifyNever(mockViewModel.updateEmail(''));
  });
}
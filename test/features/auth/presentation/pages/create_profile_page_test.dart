import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/create_profile_viewmodel.dart';

class MockCreateProfileViewModel extends StateNotifier<CreateProfileState>
    with Mock implements CreateProfileViewModel {
  MockCreateProfileViewModel() : super(CreateProfileState());
  @override set state(CreateProfileState newState) => super.state = newState;
}

void main() {
  late MockCreateProfileViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockCreateProfileViewModel();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        createProfileViewModelProvider.overrideWithValue(mockViewModel),
      ],
      child: const MaterialApp(home: CreateProfilePage(email: 'test@example.com')),
    );
  }

  group('CreateProfilePage Widget Tests', () {
    testWidgets('必須項目が未入力の場合、バリデーションエラーが表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('利用を開始する'));
      await tester.pump();
      
      expect(find.text('ユーザー名は必須です'), findsOneWidget);
      expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
    });

    testWidgets('正常に入力してボタンをタップすると、signUpが呼ばれること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      await tester.enterText(find.widgetWithText(TextFormField, 'ユーザー名 *'), 'test_user');
      await tester.enterText(find.widgetWithText(TextFormField, 'パスワード (8文字以上) *'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, '自己紹介 (任意)'), 'hello');
      
      await tester.tap(find.text('利用を開始する'));
      await tester.pump();
      
      verify(mockViewModel.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'test_user',
        bio: 'hello',
        twitterId: '',
      )).called(1);
    });
  });
}
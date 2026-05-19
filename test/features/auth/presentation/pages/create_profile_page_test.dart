import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/create_profile_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

import '../../../../mocks/mocks.mocks.dart';

class MockCreateProfileViewModel extends StateNotifier<CreateProfileState>
    with Mock
    implements CreateProfileViewModel {
  MockCreateProfileViewModel(super.state);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? bio,
    String? twitterId,
  }) {
    return super.noSuchMethod(
      Invocation.method(#signUp, [], {
        #email: email,
        #password: password,
        #username: username,
        #bio: bio,
        #twitterId: twitterId
      }),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockCreateProfileViewModel mockCreateProfileViewModel;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockCreateProfileViewModel = MockCreateProfileViewModel(CreateProfileState());
  });

  testWidgets('必須項目が未入力の場合、バリデーションエラーが表示されること', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          createProfileViewModelProvider
              .overrideWith((ref) => mockCreateProfileViewModel),
          authStateNotifierProvider
              .overrideWith((ref) => AuthStateNotifier(mockAuthRepository)),
        ],
        child: const MaterialApp(
            home: Scaffold(body: CreateProfilePage(email: 'test@example.com'))),
      ),
    );

    await tester.tap(find.text('利用を開始する'));
    await tester.pump(); 

    expect(find.text('ユーザー名は必須です'), findsOneWidget);
    expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
  });

  testWidgets('正常に入力してボタンをタップすると、signUpが呼ばれること', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          createProfileViewModelProvider
              .overrideWith((ref) => mockCreateProfileViewModel),
           authStateNotifierProvider
              .overrideWith((ref) => AuthStateNotifier(mockAuthRepository)),
        ],
        child: const MaterialApp(
            home: Scaffold(body: CreateProfilePage(email: 'test@example.com'))),
      ),
    );

    await tester.enterText(
        find.widgetWithText(CustomTextFormField, 'ユーザー名 *'), 'test_user');
    await tester.enterText(
        find.widgetWithText(CustomTextFormField, 'パスワード (8文字以上) *'),
        'password123');

    await tester.tap(find.text('利用を開始する'));

    verify(mockCreateProfileViewModel.signUp(
      email: 'test@example.com',
      password: 'password123',
      username: 'test_user',
      bio: '', 
      twitterId: '',
    )).called(1);
  });
}
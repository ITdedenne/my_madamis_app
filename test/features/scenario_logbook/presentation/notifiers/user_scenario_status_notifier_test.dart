import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';

import 'user_scenario_status_notifier_test.mocks.dart';

@GenerateMocks([GetMyListUseCase, UpdateUserScenarioStatusUseCase])
void main() {
  late MockGetMyListUseCase mockGetMyListUseCase;
  late MockUpdateUserScenarioStatusUseCase mockUpdateUserScenarioStatusUseCase;

  setUp(() {
    mockGetMyListUseCase = MockGetMyListUseCase();
    mockUpdateUserScenarioStatusUseCase = MockUpdateUserScenarioStatusUseCase();
  });

  // テスト用データ
  final tScenario = Scenario(
    id: '1',
    title: 'テストシナリオ1',
    authorName: '作者A',
    authorId: 'auth_1',
    minPlayerCount: 2,
    maxPlayerCount: 4,
    gmRequirement: GmRequirement.required,
    titleLower: 'テストシナリオ1',
    authorNameLower: '作者a',
  );

  final tInitialList = [
    UserScenario(
      scenario: tScenario,
      status: const UserScenarioStatus(isPlayed: true),
    )
  ];

  ProviderContainer createContainer() {
    return ProviderContainer(overrides: [
      getMyListUseCaseProvider.overrideWithValue(mockGetMyListUseCase),
      updateUserScenarioStatusUseCaseProvider.overrideWithValue(mockUpdateUserScenarioStatusUseCase),
    ]);
  }

  group('UserScenarioStatusNotifier', () {
    test('【正常系】初期化時にgetMyListUseCaseが呼ばれ、ステータスがロードされること', () async {
      when(mockGetMyListUseCase.call()).thenAnswer((_) async => tInitialList);

      final container = createContainer();
      
      // Notifierの初期化（コンストラクタ内で非同期処理が走る）
      container.read(userScenarioStatusProvider.notifier);
      await Future.delayed(Duration.zero); // 非同期処理を待機

      final state = container.read(userScenarioStatusProvider);
      expect(state['1'], equals(const UserScenarioStatus(isPlayed: true)));
      verify(mockGetMyListUseCase.call()).called(1);
    });

    test('【正常系】updateStatusでステータスが追加され、ユースケースが呼ばれること', () async {
      // 初期データは空とする
      when(mockGetMyListUseCase.call()).thenAnswer((_) async => []);
      when(mockUpdateUserScenarioStatusUseCase.call(any, any)).thenAnswer((_) async => {});

      final container = createContainer();
      final notifier = container.read(userScenarioStatusProvider.notifier);
      await Future.delayed(Duration.zero);

      // 新しく「所持済」として登録
      const newStatus = UserScenarioStatus(isPossessed: true);
      await notifier.updateStatus('2', newStatus);

      final state = container.read(userScenarioStatusProvider);
      expect(state['2'], equals(newStatus));
      verify(mockUpdateUserScenarioStatusUseCase.call('2', newStatus)).called(1);
    });

    test('【正常系】すべてfalseのステータスでupdateStatusを呼ぶと、未登録扱いになり状態から削除されること', () async {
      when(mockGetMyListUseCase.call()).thenAnswer((_) async => tInitialList);
      when(mockUpdateUserScenarioStatusUseCase.call(any, any)).thenAnswer((_) async => {});

      final container = createContainer();
      final notifier = container.read(userScenarioStatusProvider.notifier);
      await Future.delayed(Duration.zero);

      // 状態に '1' があることを確認
      expect(container.read(userScenarioStatusProvider).containsKey('1'), isTrue);

      // すべてfalseのステータス（未登録）に更新
      const unregisteredStatus = UserScenarioStatus();
      await notifier.updateStatus('1', unregisteredStatus);

      final state = container.read(userScenarioStatusProvider);
      
      // 状態から削除されていることを確認
      expect(state.containsKey('1'), isFalse);
      verify(mockUpdateUserScenarioStatusUseCase.call('1', unregisteredStatus)).called(1);
    });

    test('【異常系】updateStatus中にエラーが発生した場合、UIの状態が変更されないこと', () async {
      when(mockGetMyListUseCase.call()).thenAnswer((_) async => tInitialList);
      // DB更新処理でエラーを投げる
      when(mockUpdateUserScenarioStatusUseCase.call(any, any)).thenThrow(Exception('ネットワークエラー'));

      final container = createContainer();
      final notifier = container.read(userScenarioStatusProvider.notifier);
      await Future.delayed(Duration.zero);

      const newStatus = UserScenarioStatus(isPlayed: true, isPossessed: true);
      await notifier.updateStatus('1', newStatus);

      // updateが失敗するため、元の状態（isPlayed: true のみ）が保たれる
      final state = container.read(userScenarioStatusProvider);
      expect(state['1'], equals(const UserScenarioStatus(isPlayed: true)));
    });
  });
}
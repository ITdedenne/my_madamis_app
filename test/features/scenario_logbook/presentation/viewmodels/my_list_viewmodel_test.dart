import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';

class MockUserScenarioStatusNotifier extends StateNotifier<Map<String, UserScenarioStatus>> implements UserScenarioStatusNotifier {
  MockUserScenarioStatusNotifier(super.state);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> updateStatus(String scenarioId, UserScenarioStatus newStatus) async {}
}

void main() {
  // --- テスト用データ ---
  final tScenario1 = Scenario(id: '1', title: 'B_タイトル', authorName: 'Z_作者', authorId: 'auth1', minPlayerCount: 2, maxPlayerCount: 4, gmRequirement: GmRequirement.required, titleLower: 'b_タイトル', authorNameLower: 'z_作者');
  final tScenario2 = Scenario(id: '2', title: 'A_タイトル', authorName: 'Y_作者', authorId: 'auth2', minPlayerCount: 2, maxPlayerCount: 4, gmRequirement: GmRequirement.none, titleLower: 'a_タイトル', authorNameLower: 'y_作者');
  final tScenario3 = Scenario(id: '3', title: 'C_タイトル', authorName: 'X_作者', authorId: 'auth3', minPlayerCount: 2, maxPlayerCount: 4, gmRequirement: GmRequirement.optional, titleLower: 'c_タイトル', authorNameLower: 'x_作者');

  final mockAllScenarios = [tScenario1, tScenario2, tScenario3];

  final mockUserStatuses = {
    '1': const UserScenarioStatus(isPlayed: true),
    '2': const UserScenarioStatus(isPossessed: true, wantsToPlay: true),
    '3': const UserScenarioStatus(wantsToGm: true),
    '999': const UserScenarioStatus(isPlayed: true), // 存在しないシナリオID
  };

  ProviderContainer createContainer() {
    return ProviderContainer(overrides: [
      allScenariosProvider.overrideWith((ref) async => mockAllScenarios),
      // ★ 修正: Mapを直接返すのではなく、作成したMockクラスで包んで返すように変更
      userScenarioStatusProvider.overrideWith((ref) => MockUserScenarioStatusNotifier(mockUserStatuses)),
    ]);
  }

  group('MyListViewModel (MyListPageStateProvider & filteredAndSortedMyListProvider)', () {
    test('【正常系】初期状態が正しく設定されていること', () {
      final container = ProviderContainer();
      final state = container.read(myListPageStateProvider);
      
      expect(state.filter, MyListFilter.all);
      expect(state.sortOrder, SortOrder.byTitle);
    });

    test('【正常系】全シナリオとステータスが結合され、存在しないシナリオ(ID:999)は除外されること', () async {
      final container = createContainer();
      await container.read(allScenariosProvider.future); 
      
      final asyncList = container.read(filteredAndSortedMyListProvider);
      expect(asyncList.hasValue, isTrue);
      final list = asyncList.value!;
      
      expect(list.length, 3);
      expect(list.any((s) => s.scenario.id == '999'), isFalse);
    });

    test('【正常系】各フィルター(played, possessed, wantsToGm, wantsToPlay)で正しく絞り込まれること', () async {
      final container = createContainer();
      await container.read(allScenariosProvider.future);
      
      // ① isPlayed
      container.read(myListPageStateProvider.notifier).state = MyListPageState(filter: MyListFilter.played);
      var list = container.read(filteredAndSortedMyListProvider).value!;
      expect(list.length, 1);
      expect(list.first.scenario.id, '1');

      // ② isPossessed
      container.read(myListPageStateProvider.notifier).state = MyListPageState(filter: MyListFilter.possessed);
      list = container.read(filteredAndSortedMyListProvider).value!;
      expect(list.length, 1);
      expect(list.first.scenario.id, '2');

      // ③ wantsToGm
      container.read(myListPageStateProvider.notifier).state = MyListPageState(filter: MyListFilter.wantsToGm);
      list = container.read(filteredAndSortedMyListProvider).value!;
      expect(list.length, 1);
      expect(list.first.scenario.id, '3');

      // ④ wantsToPlay
      container.read(myListPageStateProvider.notifier).state = MyListPageState(filter: MyListFilter.wantsToPlay);
      list = container.read(filteredAndSortedMyListProvider).value!;
      expect(list.length, 1);
      expect(list.first.scenario.id, '2');
    });

    test('【正常系】ソート(タイトル順、作者名順)が正しく適用されること', () async {
      final container = createContainer();
      await container.read(allScenariosProvider.future);
      
      // ① byTitle (A -> B -> C)
      container.read(myListPageStateProvider.notifier).state = MyListPageState(sortOrder: SortOrder.byTitle);
      var list = container.read(filteredAndSortedMyListProvider).value!;
      expect(list[0].scenario.id, '2'); // A_タイトル
      expect(list[1].scenario.id, '1'); // B_タイトル
      expect(list[2].scenario.id, '3'); // C_タイトル

      // ② byAuthor (X -> Y -> Z)
      container.read(myListPageStateProvider.notifier).state = MyListPageState(sortOrder: SortOrder.byAuthor);
      list = container.read(filteredAndSortedMyListProvider).value!;
      expect(list[0].scenario.id, '3'); // X_作者
      expect(list[1].scenario.id, '2'); // Y_作者
      expect(list[2].scenario.id, '1'); // Z_作者
    });
  });
}
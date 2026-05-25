import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/repositories/group_search_repository.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

@GenerateMocks([GroupSearchRepository, FriendsRepository])
import 'group_search_viewmodel_test.mocks.dart';

void main() {
  late MockGroupSearchRepository mockGroupRepo;
  late MockFriendsRepository mockFriendsRepo;

  setUp(() {
    mockGroupRepo = MockGroupSearchRepository();
    mockFriendsRepo = MockFriendsRepository();
  });

GroupSearchResult createDummyResult({
    required String scenarioId,
    List<String> ngUserIds = const [],
    List<String> possessedUserIds = const [],
    List<String> wantsToGmUserIds = const [],
    List<String> wantsToPlayUserIds = const [], 
  }) {
    return GroupSearchResult(
      scenarioId: scenarioId,
      ngUserIds: ngUserIds,
      possessedUserIds: possessedUserIds,
      wantsToGmUserIds: wantsToGmUserIds,
      wantsToPlayUserIds: wantsToPlayUserIds, 
    );
  }
  Scenario createDummyScenario(String id, int maxPlayerCount) {
    return Scenario(
      id: id,
      title: 'テストシナリオ$id',
      authorName: 'テスト作者',
      authorId: 'author_1',
      minPlayerCount: maxPlayerCount,
      maxPlayerCount: maxPlayerCount,
      gmRequirement: GmRequirement.none,
      titleLower: 'テストシナリオ$id',
      authorNameLower: 'テスト作者',
    );
  }

  group('GroupSearchViewModel Tests (要件 v2.16 ロジック検証)', () {
    
    test('【人数整合性チェック】参加人数が最大プレイ人数を超えている場合は isOverCapacity が true になること', () async {
      final dummyResults = [
        createDummyResult(scenarioId: 's1'), // Max5人 (遊べる)
        createDummyResult(scenarioId: 's2'), // Max4人 (遊べる)
        createDummyResult(scenarioId: 's3'), // Max3人 (人数オーバー)
      ];

      final dummyScenarios = [
        createDummyScenario('s1', 5),
        createDummyScenario('s2', 4),
        createDummyScenario('s3', 3),
      ];

      when(mockFriendsRepo.fetchFollowingUsers()).thenAnswer((_) async => []);
      when(mockGroupRepo.findGroupScenarios(any)).thenAnswer((_) async => dummyResults);

      final container = ProviderContainer(
        overrides: [
          groupSearchRepositoryProvider.overrideWithValue(mockGroupRepo),
          friendsRepositoryProvider.overrideWithValue(mockFriendsRepo),
          allScenariosProvider.overrideWith((ref) => Future.value(dummyScenarios)),
        ],
      );
      final viewModel = container.read(groupSearchViewModelProvider.notifier);

      viewModel.toggleSelection('friend_1');
      viewModel.toggleSelection('friend_2');
      viewModel.toggleSelection('friend_3');

      await viewModel.search();
      final state = container.read(groupSearchViewModelProvider);

      final results = state.searchResults ?? [];
      expect(results.length, 3);

      final s1 = results.firstWhere((r) => r.scenario.id == 's1');
      final s2 = results.firstWhere((r) => r.scenario.id == 's2');
      final s3 = results.firstWhere((r) => r.scenario.id == 's3');

      expect(s1.isOverCapacity, isFalse);
      expect(s2.isOverCapacity, isFalse);
      expect(s3.isOverCapacity, isTrue); 
    });

    test('【惜しい！シナリオ分類】1人でもNGユーザーがいる場合は isPlayable が false になること', () async {
      final dummyResults = [
        createDummyResult(scenarioId: 's_playable', ngUserIds: []),
        createDummyResult(scenarioId: 's_near_miss', ngUserIds: ['user1']),
      ];

      final dummyScenarios = [
        createDummyScenario('s_playable', 4),
        createDummyScenario('s_near_miss', 4),
      ];

      when(mockFriendsRepo.fetchFollowingUsers()).thenAnswer((_) async => []);
      when(mockGroupRepo.findGroupScenarios(any)).thenAnswer((_) async => dummyResults);

      final container = ProviderContainer(
        overrides: [
          groupSearchRepositoryProvider.overrideWithValue(mockGroupRepo),
          friendsRepositoryProvider.overrideWithValue(mockFriendsRepo),
          allScenariosProvider.overrideWith((ref) => Future.value(dummyScenarios)),
        ],
      );
      final viewModel = container.read(groupSearchViewModelProvider.notifier);

      viewModel.toggleSelection('friend_1');
      await viewModel.search();
      final state = container.read(groupSearchViewModelProvider);

      final results = state.searchResults ?? [];
      final playable = results.where((r) => r.isPlayable).toList();
      final nearMiss = results.where((r) => !r.isPlayable).toList();

      expect(playable.length, 1);
      expect(playable.first.scenario.id, 's_playable');
      expect(nearMiss.length, 1);
      expect(nearMiss.first.scenario.id, 's_near_miss');
    });

    test('''
【立卓率最大化・ビジネスロジック】
検索結果が要件定義の優先度(PL希望 > 所持 > 外部GM > 名前順)で正しくソートされること。
理由: 「遊びたい熱量が高いシナリオ」や「GMの目処が立っているシナリオ」を最上位に提示し、
機会損失を防ぐというドメイン要件(4.5.2)を満たすため。
''', () async {
      final dummyScenarios = [
        createDummyScenario('s_normal', 4),
        createDummyScenario('s_wants_play', 4),
        createDummyScenario('s_possessed', 4),
        createDummyScenario('s_external_gm', 4),
      ];

      final dummyResults = [
        createDummyResult(scenarioId: 's_normal'), // 特になし(最下位)
        createDummyResult(scenarioId: 's_external_gm', possessedUserIds: ['friend_99']), // 外部GM候補(3位)
        createDummyResult(scenarioId: 's_wants_play', wantsToPlayUserIds: ['friend_1']), // PL希望(1位)
        createDummyResult(scenarioId: 's_possessed', possessedUserIds: ['friend_2']), // 所持(2位)
      ];

      when(mockFriendsRepo.fetchFollowingUsers()).thenAnswer((_) async => []);
      when(mockGroupRepo.findGroupScenarios(any)).thenAnswer((_) async => dummyResults);

      final container = ProviderContainer(
        overrides: [
          groupSearchRepositoryProvider.overrideWithValue(mockGroupRepo),
          friendsRepositoryProvider.overrideWithValue(mockFriendsRepo),
          allScenariosProvider.overrideWith((ref) => Future.value(dummyScenarios)),
        ],
      );
      
      final viewModel = container.read(groupSearchViewModelProvider.notifier);
      viewModel.toggleSelection('friend_1');
      viewModel.toggleSelection('friend_2');

      await viewModel.search();
      final state = container.read(groupSearchViewModelProvider);
      final results = state.searchResults ?? [];

      expect(results.length, 4);
      // ViewModelのソート処理が正しく実装されているかを検証
      expect(results[0].scenario.id, 's_wants_play', reason: 'PL希望者がいるシナリオが最優先');
      expect(results[1].scenario.id, 's_possessed', reason: '所持者がいるシナリオが2番目');
      expect(results[2].scenario.id, 's_external_gm', reason: '外部GM候補がいるシナリオが3番目');
      expect(results[3].scenario.id, 's_normal', reason: '何も該当しないシナリオは最後');
    });
  });
}
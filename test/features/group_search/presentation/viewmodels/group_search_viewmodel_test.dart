import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

import 'group_search_viewmodel_test.mocks.dart';

// Mockitoを使わず、安全にプロバイダの値を返す専用の偽物クラスを作成
class FakeRef extends Fake implements Ref {
  final List<Scenario> dummyScenarios;
  FakeRef(this.dummyScenarios);

  @override
  T read<T>(ProviderListenable<T> provider) {
    final typeString = T.toString();
    if (typeString.contains('List<Scenario>')) {
      return Future.value(dummyScenarios) as T;
    } else if (typeString.contains('AuthState')) {
      return const AuthState(username: 'MyName') as T;
    }
    // 想定外のプロバイダが呼ばれた場合は空のFutureを返す（クラッシュ防止）
    try {
      return Future.value() as T;
    } catch (_) {
      throw UnimplementedError('FakeRef: 未サポートの型 ($typeString) が呼ばれました');
    }
  }
}

// モック自動生成から Ref を除外し、エラーを防止
@GenerateMocks([FriendsRepository, FindGroupScenariosUseCase])
void main() {
  late GroupSearchViewModel viewModel;
  late MockFriendsRepository mockFriendsRepository;
  late MockFindGroupScenariosUseCase mockUseCase;
  late FakeRef fakeRef;

  // テスト用のダミーフレンズデータ
  final dummyFriends = [
    User(id: 'friend1', username: 'Friend One', publicUserId: 'F000001'),
    User(id: 'friend2', username: 'Friend Two', publicUserId: 'F000002'),
    User(id: 'friend3', username: 'Friend Three', publicUserId: 'F000003'),
    User(id: 'friend4', username: 'Friend Four', publicUserId: 'F000004'),
  ];

  // テスト用のダミーシナリオデータ
  final dummyScenarios =  [
    Scenario(
      id: 'scen1',
      title: 'A Test Scenario 1',
      authorName: 'Author A',
      authorId: 'auth_a',
      titleLower: 'a test scenario 1',
      authorNameLower: 'author a',
      minPlayerCount: 4,
      maxPlayerCount: 4,
      gmRequirement: GmRequirement.required,
    ),
    Scenario(
      id: 'scen2',
      title: 'B Test Scenario 2',
      authorName: 'Author B',
      authorId: 'auth_b',
      titleLower: 'b test scenario 2',
      authorNameLower: 'author b',
      minPlayerCount: 3,
      maxPlayerCount: 5,
      gmRequirement: GmRequirement.none,
    ),
  ];

  setUp(() {
    mockFriendsRepository = MockFriendsRepository();
    mockUseCase = MockFindGroupScenariosUseCase();
    fakeRef = FakeRef(dummyScenarios); 

    // フレンズ取得の振る舞い設定
    when(mockFriendsRepository.fetchFollowingUsers())
        .thenAnswer((_) async => dummyFriends);

    viewModel = GroupSearchViewModel(mockFriendsRepository, mockUseCase, fakeRef);
  });

  group('初期化とフレンズ管理', () {
    test('正常系: ViewModel生成時にフレンド一覧を自動で取得する', () async {
      await Future.delayed(Duration.zero);
      expect(viewModel.state.isLoadingFriends, false);
      expect(viewModel.state.friends.length, 4);
      verify(mockFriendsRepository.fetchFollowingUsers()).called(1);
    });

    test('正常系: フレンド名によるローカルフィルタリングが正しく機能する', () async {
      await Future.delayed(Duration.zero);
      viewModel.updateFriendFilter('Two');
      expect(viewModel.state.filteredFriends.length, 1);
      expect(viewModel.state.filteredFriends.first.username, 'Friend Two');
    });

    test('正常系・境界値: メンバー選択処理と上限(8人)の制限が機能する', () {
      viewModel.toggleSelection('friend1');
      expect(viewModel.state.selectedFriendIds.contains('friend1'), true);
      expect(viewModel.state.totalPlayers, 2); 

      viewModel.toggleSelection('friend1'); 
      expect(viewModel.state.selectedFriendIds.contains('friend1'), false);

      for (int i = 0; i < 8; i++) {
        viewModel.toggleSelection('user$i');
      }
      expect(viewModel.state.isSelectionLimitReached, true);
      
      viewModel.toggleSelection('user8'); 
      expect(viewModel.state.selectedFriendIds.length, 8); 
    });
  });

  group('検索ロジックとキャッシュ制御', () {
    test('正常系: メンバーを選択して検索を実行し、画面表示用アイテムが生成される', () async {
      await Future.delayed(Duration.zero);
      viewModel.toggleSelection('friend1');

      final mockResult = [
        const GroupSearchResult(
          scenarioId: 'scen2',
          ngUserIds: [],
          wantsToPlayUserIds: ['friend1'],
          possessedUserIds: [],
          wantsToGmUserIds: [],
        )
      ];
      when(mockUseCase.call(any)).thenAnswer((_) async => mockResult);

      await viewModel.search();

      expect(viewModel.state.isSearching, false);
      expect(viewModel.state.searchResults!.length, 2);
      
      final scen2Result = viewModel.state.searchResults!.firstWhere((r) => r.scenario.id == 'scen2');
      expect(scen2Result.isPlayerCountMatch, false); 
      expect(scen2Result.isPlayable, true); 
      expect(scen2Result.hasWantsToPlay, true);
    });

    test('ロジック検証: 直前と同じメンバー構成で検索した場合、通信をスキップしキャッシュを利用する', () async {
      await Future.delayed(Duration.zero);
      viewModel.toggleSelection('friend1');

      when(mockUseCase.call(any)).thenAnswer((_) async => const []);

      await viewModel.search(); 
      verify(mockUseCase.call(['friend1'])).called(1);

      await viewModel.search(); 
      verifyNever(mockUseCase.call(any)); 
    });
  });

  group('内部GMと人数整合性判定', () {
    test('ロジック検証: 内部GMをONにすると、シナリオの必要PL人数から-1されて計算される', () async {
      await Future.delayed(Duration.zero);
      
      // 自分(1) + フレンド(4) = 全体で5人のグループを作る
      viewModel.toggleSelection('friend1');
      viewModel.toggleSelection('friend2');
      viewModel.toggleSelection('friend3'); 
      viewModel.toggleSelection('friend4'); 

      when(mockUseCase.call(any)).thenAnswer((_) async => const []);

      // 内部GMをONにする（全体5人 → GM1人、PL4人として計算されるようになる）
      viewModel.toggleHasInternalGm(true);

      await Future.delayed(const Duration(milliseconds: 50));

      await viewModel.search();

      // scen1 は「4人用」かつ「GM必須」のシナリオ
      // PL4人として計算された結果、人数がピッタリ一致(isPlayerCountMatch == true)するはず
      final scen1Result = viewModel.state.searchResults!.firstWhere((r) => r.scenario.id == 'scen1');
      expect(scen1Result.isPlayerCountMatch, true); 
    });

    test('ロジック検証: 内部GMがONの場合、GM不要(none)のシナリオは検索結果から除外される', () async {
       await Future.delayed(Duration.zero);
       viewModel.toggleSelection('friend1');
       when(mockUseCase.call(any)).thenAnswer((_) async => const []);

       viewModel.toggleHasInternalGm(true);
       await viewModel.search();

       final containsScen2 = viewModel.state.searchResults!.any((r) => r.scenario.id == 'scen2');
       expect(containsScen2, false);
    });
  });

  group('ソート順の検証', () {
    test('ロジック検証: プレイ不可(NG)のシナリオは、常に検索結果リストの末尾に追いやられる', () async {
       await Future.delayed(Duration.zero);
       viewModel.toggleSelection('friend1');
       
       final mockResult = [
         const GroupSearchResult(
           scenarioId: 'scen1', 
           ngUserIds: ['friend1'],
           wantsToPlayUserIds: [], possessedUserIds: [], wantsToGmUserIds: [],
         ),
       ];
       when(mockUseCase.call(any)).thenAnswer((_) async => mockResult);
       await viewModel.search();

       expect(viewModel.state.searchResults!.first.scenario.id, 'scen2');
       expect(viewModel.state.searchResults!.last.scenario.id, 'scen1');
       expect(viewModel.state.searchResults!.last.isPlayable, false);
    });
  });
}
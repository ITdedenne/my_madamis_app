import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/player_finder/data/repositories/player_finder_repository.dart';

import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart';
import 'package:my_madamis_app/features/player_finder/presentation/viewmodels/player_finder_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';
import 'package:my_madamis_app/models/ModelProvider.dart'; // AmplifyのUserクラス取得用

@GenerateMocks([PlayerFinderRepository])
import 'player_finder_viewmodel_test.mocks.dart';

void main() {
  late MockPlayerFinderRepository mockRepo;

  setUp(() {
    mockRepo = MockPlayerFinderRepository();
  });

  // 実際のエンティティの構造に合わせたダミー生成ヘルパー
  SearchedUser createDummyUser({
    required String id,
    bool isPlayed = false,
    bool isPossessed = false,
    bool wantsToGm = false,
    bool wantsToPlay = false,
  }) {
    return SearchedUser(
      // 実際の Amplify User モデルを渡す
      user: User(id: id, username: 'User_$id', publicUserId: 'pub_$id'),
      isPlayed: isPlayed,
      isPossessed: isPossessed,
      wantsToGm: wantsToGm,
      wantsToPlay: wantsToPlay,
    );
  }

  group('PlayerFinderViewModel Tests', () {
    const testScenarioId = 'scenario_123';

    test('【GM候補検索モード切替】GMモードを指定した場合、Repositoryに "gm" モードとしてリクエストが飛ぶこと', () async {
      // どのモードで呼ばれても空リストを返すようにモックを柔軟に設定
      when(mockRepo.findUnplayedFriends(any, mode: anyNamed('mode')))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          playerFinderRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      
      final viewModel = container.read(playerFinderProvider(testScenarioId).notifier);

      // 初期化時の非同期処理(playerモードでの検索)が完了するのを確実に待つ
      await viewModel.refresh();

      // 実行: モードをGMに切り替える
      viewModel.setMode(PlayerFinderMode.gm);
      
      // モード切替後の再検索(_search)が完了するのを少し待機
      await Future.delayed(const Duration(milliseconds: 50));

      // 検証: gmモードでリポジトリが呼ばれたか
      verify(mockRepo.findUnplayedFriends(testScenarioId, mode: 'gm')).called(1);
    });

    test('【PL希望者の強調ソート】PL探しモード時、データが正常にViewModelに反映されること', () async {
      final dummyUsers = [
        createDummyUser(id: 'u1', wantsToPlay: false),
        createDummyUser(id: 'u2', wantsToPlay: true), // PL希望
      ];

      when(mockRepo.findUnplayedFriends(any, mode: anyNamed('mode')))
          .thenAnswer((_) async => dummyUsers);

      final container = ProviderContainer(
        overrides: [
          playerFinderRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      
      final viewModel = container.read(playerFinderProvider(testScenarioId).notifier);
      
      // コンストラクタで走る_search()ではなく、明示的にawaitできるrefresh()を呼んで完了を待機する
      await viewModel.refresh();

      final state = container.read(playerFinderProvider(testScenarioId));

      expect(state.users.hasError, false, reason: state.users.error?.toString());

      // 検証: データが正しくパースされ state に格納されているか
      expect(state.users.value?.length, 2);
      expect(state.users.value?[1].wantsToPlay, isTrue);
    });
  });
}
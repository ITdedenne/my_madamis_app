import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/user_search_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart'; // Userクラスのため
import 'package:my_madamis_app/providers.dart';

@GenerateMocks([FriendsRepository])
import 'user_search_viewmodel_test.mocks.dart';

void main() {
  late MockFriendsRepository mockFriendsRepo;

  setUp(() {
    mockFriendsRepo = MockFriendsRepository();
  });

  group('UserSearchViewModel Tests (非機能要件・インフラ保護検証)', () {
    test('''
【コスト・インフラ保護】
既にフレンズが上限(100人)に達している場合、APIリクエスト(followUser)を
絶対に送信せず、クライアントサイドでエラーを返すこと。
''', () async {
      // ViewModelのStateではなく、Repositoryのメソッドが「100人」を返すようにモックする
      when(mockFriendsRepo.getFollowingCount()).thenAnswer((_) async => 100);
      
      // APIが呼ばれた場合は正常終了を返すように設定 (実際には呼ばれてはいけない)
      when(mockFriendsRepo.followUser(any)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          friendsRepositoryProvider.overrideWithValue(mockFriendsRepo),
        ],
      );
      
      final viewModel = container.read(userSearchViewModelProvider.notifier);

      // Stringではなく、要件に合わせたダミーのUserオブジェクトを渡す
      final dummyTargetUser = User(
        id: 'user_101', 
        publicUserId: 'pub_101', 
        username: 'Target User'
      );

      // 実行: 101人目をフォローしようとする
      await viewModel.followUser(dummyTargetUser);
      final state = container.read(userSearchViewModelProvider);

      // 検証1: [最重要] Repositoryの followUser が『一度も呼ばれていないこと』
      verifyNever(mockFriendsRepo.followUser(any));

      // 検証2: ユーザーにはUI上で適切な上限エラーメッセージがセットされていること
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('100人')); 
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/user_search_viewmodel.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

@GenerateMocks([FriendsRepository])
import 'user_search_viewmodel_test.mocks.dart';

// 他のViewModelへの依存(ロード処理)を隔離するためのモック
class MockFriendsViewModel extends StateNotifier<FriendsState> implements FriendsViewModel {
  MockFriendsViewModel() : super(FriendsState());
  
  @override
  Future<void> loadFollowingUsers() async {}

  @override
  Future<void> unfollowUser(String userId) async {}
  
  @override
  void clearMessages() {}
}

void main() {
  late MockFriendsRepository mockFriendsRepo;

  setUp(() {
    mockFriendsRepo = MockFriendsRepository();
  });

  group('UserSearchViewModel Tests (非機能要件・インフラ保護検証)', () {
    test('''
【コスト・インフラ保護】
検索キーワードが2文字未満の場合、APIリクエスト(searchUsers)を
送信せず、クライアントサイドでブロックして無駄なGSI検索コストを削減すること。
''', () async {
      final container = ProviderContainer(
        overrides: [
          friendsRepositoryProvider.overrideWithValue(mockFriendsRepo),
        ],
      );
      final viewModel = container.read(userSearchViewModelProvider.notifier);

      await viewModel.search('a');
      final state = container.read(userSearchViewModelProvider);

      verifyNever(mockFriendsRepo.searchUsers(any));
      expect(state.errorMessage, '検索キーワードは2文字以上入力してください');
      expect(state.searchResults, isEmpty);
    });

    test('''
【コスト・インフラ保護】
既にフレンズが上限(100人)に達している場合、APIリクエスト(followUser)を
絶対に送信せず、クライアントサイドでエラーを返すこと。
''', () async {
      when(mockFriendsRepo.getFollowingCount()).thenAnswer((_) async => 100);
      when(mockFriendsRepo.followUser(any)).thenAnswer((_) async {});

      final mockFriendsVM = MockFriendsViewModel();

      final container = ProviderContainer(
        overrides: [
          friendsRepositoryProvider.overrideWithValue(mockFriendsRepo),
          friendsViewModelProvider.overrideWith((ref) => mockFriendsVM),
        ],
      );
      
      final viewModel = container.read(userSearchViewModelProvider.notifier);

      final dummyTargetUser = User(
        id: 'user_101', 
        publicUserId: 'pub_101', 
        username: 'Target User'
      );

      await viewModel.followUser(dummyTargetUser);
      final state = container.read(userSearchViewModelProvider);

      verifyNever(mockFriendsRepo.followUser(any));

      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('100人')); 
    });
  });
}
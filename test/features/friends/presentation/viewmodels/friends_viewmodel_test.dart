import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_madamis_app/features/friends/domain/repositories/friends_repository.dart';
import 'package:my_madamis_app/features/friends/presentation/viewmodels/friends_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

@GenerateMocks([FriendsRepository])
import 'friends_viewmodel_test.mocks.dart';

void main() {
  late MockFriendsRepository mockFriendsRepo;

  setUp(() {
    mockFriendsRepo = MockFriendsRepository();
  });

  group('FriendsViewModel Tests (コスト・インフラ保護検証)', () {
    test('【コスト対策】 フレンズ一覧の読み込み時、API(fetchFollowingUsers)は初期化時の1回のみ呼ばれること。ローカルフィルタリングでの運用が担保されていること', () async {
      final dummyUsers = [
        User(id: 'user_1', publicUserId: 'pub_1', username: 'Friend A'),
        User(id: 'user_2', publicUserId: 'pub_2', username: 'Friend B'),
      ];
      when(mockFriendsRepo.fetchFollowingUsers()).thenAnswer((_) async => dummyUsers);

      final viewModel = FriendsViewModel(mockFriendsRepo);

      await Future.delayed(Duration.zero);

      verify(mockFriendsRepo.fetchFollowingUsers()).called(1);
      expect(viewModel.state.followingUsers.length, 2);
    });

    test('【コスト対策】 アンフォロー時、一覧を再取得するのではなくローカルのStateから削除し、余分なReadコスト(fetchFollowingUsers)を発生させないこと', () async {
      final dummyUsers = [
        User(id: 'user_1', publicUserId: 'pub_1', username: 'Friend A'),
        User(id: 'user_2', publicUserId: 'pub_2', username: 'Friend B'),
      ];
      when(mockFriendsRepo.fetchFollowingUsers()).thenAnswer((_) async => dummyUsers);
      when(mockFriendsRepo.unfollowUser(any)).thenAnswer((_) async {});

      final viewModel = FriendsViewModel(mockFriendsRepo);
      await Future.delayed(Duration.zero);

      await viewModel.unfollowUser('user_1');

      verify(mockFriendsRepo.unfollowUser('user_1')).called(1);

      // fetchFollowingUsers は初期ロード時の1回のみであることを検証
      verify(mockFriendsRepo.fetchFollowingUsers()).called(1);

      expect(viewModel.state.followingUsers.length, 1);
      expect(viewModel.state.followingUsers.first.id, 'user_2');
      expect(viewModel.state.successMessage, '解除しました');
    });
  });
}
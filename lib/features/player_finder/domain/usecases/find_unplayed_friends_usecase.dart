import 'package:my_madamis_app/features/player_finder/data/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart'; // ★ 追加

class FindUnplayedFriendsUseCase {
  final PlayerFinderRepository _repository;
  FindUnplayedFriendsUseCase(this._repository);

  Future<List<SearchedUser>> call(String scenarioId) { // ★ 戻り値変更
    return _repository.findUnplayedFriends(scenarioId);
  }
}
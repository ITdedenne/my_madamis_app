import 'package:my_madamis_app/features/player_finder/data/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart';

class FindUnplayedFriendsUseCase {
  final PlayerFinderRepository _repository;
  FindUnplayedFriendsUseCase(this._repository);

  Future<List<SearchedUser>> call(String scenarioId, {String mode = 'player'}) {
    return _repository.findUnplayedFriends(scenarioId, mode: mode);
  }
}
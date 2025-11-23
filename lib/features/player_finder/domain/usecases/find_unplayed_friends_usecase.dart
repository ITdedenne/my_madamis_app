// ファイルパス: lib/features/player_finder/domain/usecases/find_unplayed_friends_usecase.dart

import 'package:my_madamis_app/features/player_finder/domain/repositories/player_finder_repository.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class FindUnplayedFriendsUseCase {
  final PlayerFinderRepository _repository;
  FindUnplayedFriendsUseCase(this._repository);

  Future<List<User>> call(String scenarioId) {
    return _repository.findUnplayedFriends(scenarioId);
  }
}
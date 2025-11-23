// ファイルパス: lib/features/player_finder/domain/repositories/player_finder_repository.dart

import 'package:my_madamis_app/models/ModelProvider.dart';

abstract class PlayerFinderRepository {
  /// 指定したシナリオを未通過のフレンズを取得 (機能4)
  Future<List<User>> findUnplayedFriends(String scenarioId);
}
import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart';

abstract class PlayerFinderRepository {
  /// 指定したシナリオを未通過のフレンズを取得
  /// mode: 'player' (デフォルト) | 'gm'
  Future<List<SearchedUser>> findUnplayedFriends(String scenarioId, {String mode});
}
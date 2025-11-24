import 'package:my_madamis_app/features/player_finder/domain/entities/searched_user.dart'; // ★ 変更

abstract class PlayerFinderRepository {
  /// 指定したシナリオを未通過のフレンズを取得 (機能4)
  /// 戻り値を User から SearchedUser に変更
  Future<List<SearchedUser>> findUnplayedFriends(String scenarioId);
}
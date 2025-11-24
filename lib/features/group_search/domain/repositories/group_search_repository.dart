// ファイルパス: lib/features/group_search/domain/repositories/group_search_repository.dart

abstract class GroupSearchRepository {
  /// 指定したフレンズたちと遊べるシナリオ（全員未通過かつ自分所持orGM希望）のIDリストを取得
  Future<List<String>> findGroupScenarios(List<String> friendIds);
}
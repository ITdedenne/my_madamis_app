// ファイルパス: lib/features/group_search/domain/repositories/group_search_repository.dart

import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';

abstract class GroupSearchRepository {
  /// 指定したフレンズたちと遊べるシナリオを取得
  /// 返り値には「フレンズがPL希望しているか」のメタデータが含まれる
  Future<List<GroupSearchResult>> findGroupScenarios(List<String> friendIds);
}
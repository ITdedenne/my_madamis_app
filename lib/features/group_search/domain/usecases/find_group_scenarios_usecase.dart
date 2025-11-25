// ファイルパス: lib/features/group_search/domain/usecases/find_group_scenarios_usecase.dart

import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';
import 'package:my_madamis_app/features/group_search/domain/repositories/group_search_repository.dart';

class FindGroupScenariosUseCase {
  final GroupSearchRepository _repository;
  
  FindGroupScenariosUseCase(this._repository);

  Future<List<GroupSearchResult>> call(List<String> friendIds) async {
    if (friendIds.isEmpty) {
      throw Exception('フレンズを選択してください。');
    }
    if (friendIds.length > 8) {
      throw Exception('選択できるフレンズは8人までです。');
    }
    return await _repository.findGroupScenarios(friendIds);
  }
}
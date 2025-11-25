import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';

abstract class GroupSearchRepository {
  Future<List<GroupSearchResult>> findGroupScenarios(List<String> friendIds);
}
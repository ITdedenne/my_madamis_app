import 'package:my_madamis_app/features/group_search/domain/entities/group_search_result.dart';

abstract class GroupSearchRepository {
  Future<GroupSearchResponse> findGroupScenarios(List<String> friendIds);
}
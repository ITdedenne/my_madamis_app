// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_results_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; // allScenariosProvider
import 'package:my_madamis_app/providers.dart';

// familyを使って引数(friendIds)を受け取る
final groupSearchResultsProvider = FutureProvider.family.autoDispose<List<Scenario>, List<String>>((ref, friendIds) async {
  final useCase = FindGroupScenariosUseCase(ref.watch(groupSearchRepositoryProvider));
  
  // 1. Lambdaから条件に合うシナリオIDのリストを取得
  final matchedScenarioIds = await useCase(friendIds);
  
  // 2. クライアントの全シナリオキャッシュを取得
  final allScenarios = await ref.watch(allScenariosProvider.future);
  
  // 3. IDリストに基づいてScenarioオブジェクトを抽出
  // containsチェックを高速化するためSetに変換
  final idSet = matchedScenarioIds.toSet();
  
  final results = allScenarios.where((s) => idSet.contains(s.id)).toList();
  
  // ソート順: タイトル順 (デフォルト)
  results.sort((a, b) => a.title.compareTo(b.title));
  
  return results;
});
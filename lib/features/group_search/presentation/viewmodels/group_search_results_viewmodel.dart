// ファイルパス: lib/features/group_search/presentation/viewmodels/group_search_results_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/domain/usecases/find_group_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; // allScenariosProvider
import 'package:my_madamis_app/providers.dart';

// UI表示用のラッパークラス
class GroupSearchDisplayItem {
  final Scenario scenario;
  final bool isFriendWantsToPlay; // フレンズからのリクエストあり

  GroupSearchDisplayItem({
    required this.scenario,
    required this.isFriendWantsToPlay,
  });
}

// familyを使って引数(friendIds)を受け取る
final groupSearchResultsProvider = FutureProvider.family.autoDispose<List<GroupSearchDisplayItem>, List<String>>((ref, friendIds) async {
  final useCase = FindGroupScenariosUseCase(ref.watch(groupSearchRepositoryProvider));
  
  // 1. Lambdaから条件に合うシナリオ情報（ID + PL希望フラグ）を取得
  final matchedResults = await useCase(friendIds);
  
  // 2. クライアントの全シナリオキャッシュを取得
  final allScenarios = await ref.watch(allScenariosProvider.future);
  
  // 3. マッチング処理 (高速化のためMap化)
  // Map<ScenarioId, isFriendWantsToPlay>
  final matchMap = {
    for (var r in matchedResults) r.scenarioId: r.isFriendWantsToPlay
  };
  
  final List<GroupSearchDisplayItem> displayItems = [];

  for (var scenario in allScenarios) {
    if (matchMap.containsKey(scenario.id)) {
      displayItems.add(GroupSearchDisplayItem(
        scenario: scenario,
        isFriendWantsToPlay: matchMap[scenario.id]!,
      ));
    }
  }
  
  // 4. ソートロジック (要件 4.5.2 / 3.5.1)
  // 優先順位: 
  // 1. フレンズがPL希望している (isFriendWantsToPlay == true)
  // 2. タイトル順 (50音順)
  displayItems.sort((a, b) {
    if (a.isFriendWantsToPlay != b.isFriendWantsToPlay) {
      // trueが先 (true=1, false=0的な降順)
      return a.isFriendWantsToPlay ? -1 : 1;
    }
    return a.scenario.title.compareTo(b.scenario.title);
  });
  
  return displayItems;
});
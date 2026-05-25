// ファイルパス: lib/features/player_finder/presentation/viewmodels/player_finder_search_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';

final playerFinderSearchViewModelProvider =
    StateNotifierProvider.autoDispose<PlayerFinderSearchViewModel, SearchScenariosState>((ref) {
  return PlayerFinderSearchViewModel();
});

final _playerFinderFilteredScenariosProvider = Provider.autoDispose<AsyncValue<List<Scenario>>>((ref) {
  final allScenariosAsync = ref.watch(allScenariosProvider);
  final searchState = ref.watch(playerFinderSearchViewModelProvider);

  return allScenariosAsync.when(
    data: (allScenarios) {
      // リストをコピーして変更可能な状態にする
      List<Scenario> filtered = List.of(allScenarios);

      // ここで強制的にタイトル順にソートし、「所持優先」の並びをリセットする
      // (よみがなフィールドがあれば compareTo(b.yomigana) を推奨)
      filtered.sort((a, b) => a.title.compareTo(b.title));

      final filter = searchState.filter;
      final rawTerm = searchState.searchTerm.toLowerCase().trim();
      
      if (rawTerm.isNotEmpty) {
        final keywords = rawTerm.replaceAll('　', ' ').split(' ').where((w) => w.isNotEmpty);
        filtered = filtered.where((s) {
          return keywords.every((keyword) =>
              s.titleLower.contains(keyword) || 
              s.authorNameLower.contains(keyword));
        }).toList();
      }
      
      final start = filter.playerCountRange.start.round();
      final end = filter.playerCountRange.end.round();
      if (start > 1 || end < 15) {
         filtered = filtered.where((s) {
          return s.minPlayerCount <= end && s.maxPlayerCount >= start;
        }).toList();
      }

      if (filter.gmRequirement != null) {
        filtered = filtered.where((s) => s.gmRequirement == filter.gmRequirement).toList();
      }

      if (filter.authorName != null && filter.authorName!.isNotEmpty) {
        filtered = filtered.where((s) => s.authorName == filter.authorName).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// 3. 表示用リスト (ページネーション上限適用)
final playerFinderDisplayedScenariosProvider = Provider.autoDispose<AsyncValue<List<Scenario>>>((ref) {
  final filteredAsync = ref.watch(_playerFinderFilteredScenariosProvider);
  final limit = ref.watch(playerFinderSearchViewModelProvider).displayLimit;

  return filteredAsync.whenData((scenarios) {
    if (scenarios.length > limit) {
      return scenarios.sublist(0, limit);
    }
    return scenarios;
  });
});

class PlayerFinderSearchViewModel extends SearchScenariosViewModel {}
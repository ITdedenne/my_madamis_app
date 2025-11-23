import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; // allScenariosProviderを利用
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart'; // クラス定義のみ再利用

// -----------------------------------------------------------------------------
// プレイヤーファインダー機能専用の検索Provider定義
// -----------------------------------------------------------------------------

// 1. 検索状態管理
// ★改善: autoDispose を付与。この画面を離れたら検索条件をリセットする。
final playerFinderSearchViewModelProvider =
    StateNotifierProvider.autoDispose<PlayerFinderSearchViewModel, SearchScenariosState>((ref) {
  return PlayerFinderSearchViewModel();
});

// 2. フィルタリングロジック (計算用)
final _playerFinderFilteredScenariosProvider = Provider.autoDispose<AsyncValue<List<Scenario>>>((ref) {
  final allScenariosAsync = ref.watch(allScenariosProvider);
  // ★重要: プレイヤーファインダー専用の検索状態を監視
  final searchState = ref.watch(playerFinderSearchViewModelProvider);

  return allScenariosAsync.when(
    data: (allScenarios) {
      List<Scenario> filtered = allScenarios;
      final filter = searchState.filter;
      
      // ★改善: スペース区切りのAND検索に対応
      final rawTerm = searchState.searchTerm.toLowerCase().trim();
      if (rawTerm.isNotEmpty) {
        // 全角スペースを半角に変換して分割
        final keywords = rawTerm.replaceAll('　', ' ').split(' ').where((w) => w.isNotEmpty);
        
        filtered = filtered.where((s) {
          // すべてのキーワードが含まれているか (AND検索)
          return keywords.every((keyword) =>
              s.titleLower.contains(keyword) || s.authorNameLower.contains(keyword));
        }).toList();
      }
      
      // 人数フィルター
      final start = filter.playerCountRange.start.round();
      final end = filter.playerCountRange.end.round();
      if (start > 1 || end < 15) {
         filtered = filtered.where((s) {
          return s.minPlayerCount <= end && s.maxPlayerCount >= start;
        }).toList();
      }

      // GM要否
      if (filter.gmRequirement != null) {
        filtered = filtered.where((s) => s.gmRequirement == filter.gmRequirement).toList();
      }

      // 作者名
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

// クラス自体は継承して利用（ロジックは共通なため）
class PlayerFinderSearchViewModel extends SearchScenariosViewModel {
  // 必要であればプレイヤーファインダー特有のメソッドをここでオーバーライド可能
  // 例: プレイヤーファインダーでは「リスト更新時の成功メッセージ」は不要など
}
// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';

// --- 定数: 1回に読み込む件数 ---
const int _kPageLimit = 48;

class SearchFilter {
  final RangeValues playerCountRange;
  final GmRequirement? gmRequirement;
  final String? authorName;

  SearchFilter({
    required this.playerCountRange,
    this.gmRequirement,
    this.authorName,
  });
  
  factory SearchFilter.initial() => SearchFilter(playerCountRange: const RangeValues(1, 15));

  bool get isInitial =>
      playerCountRange.start == 1 &&
      playerCountRange.end == 15 &&
      gmRequirement == null &&
      authorName == null;
}

class SearchScenariosState {
  final String? errorMessage;
  final String? successMessage;
  final SearchFilter filter;
  final String searchTerm;
  final int displayLimit;

  SearchScenariosState({
    this.errorMessage,
    this.successMessage,
    SearchFilter? filter,
    this.searchTerm = '',
    this.displayLimit = _kPageLimit,
  }) : filter = filter ?? SearchFilter.initial();

  SearchScenariosState copyWith({
    String? errorMessage,
    String? successMessage,
    SearchFilter? filter,
    String? searchTerm,
    int? displayLimit,
  }) {
    return SearchScenariosState(
      errorMessage: errorMessage,
      successMessage: successMessage,
      filter: filter ?? this.filter,
      searchTerm: searchTerm ?? this.searchTerm,
      displayLimit: displayLimit ?? this.displayLimit,
    );
  }
}

final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  return SearchScenariosViewModel();
});

// 1. まず全件から絞り込んだリストを作成するProvider (計算用)
final _filteredAllScenariosProvider = Provider<AsyncValue<List<Scenario>>>((ref) {
  final allScenariosAsync = ref.watch(allScenariosProvider);
  final searchState = ref.watch(searchScenariosViewModelProvider);

  return allScenariosAsync.when(
    data: (allScenarios) {
      List<Scenario> filtered = allScenarios;

      // 検索フィルターロジック
      final filter = searchState.filter;
      final rawTerm = searchState.searchTerm.toLowerCase().trim();
      
      // 検索ワードによる絞り込み (AND検索対応)
      if (rawTerm.isNotEmpty) {
        // 全角スペースを半角に変換してから分割し、空文字を除外
        final keywords = rawTerm.replaceAll('　', ' ').split(' ').where((w) => w.isNotEmpty);

        filtered = filtered.where((s) {
          // すべてのキーワードが含まれているか (AND検索)
          // タイトルか作者名のどちらかにキーワードが含まれていればヒットとみなす
          return keywords.every((keyword) =>
              s.titleLower.contains(keyword) || 
              s.authorNameLower.contains(keyword));
        }).toList();
      }
      
      // 人数による絞り込み
      final start = filter.playerCountRange.start.round();
      final end = filter.playerCountRange.end.round();
      if (start > 1 || end < 15) {
         filtered = filtered.where((s) {
          return s.minPlayerCount <= end && s.maxPlayerCount >= start;
        }).toList();
      }

      // GM要否による絞り込み
      if (filter.gmRequirement != null) {
        filtered = filtered.where((s) => s.gmRequirement == filter.gmRequirement).toList();
      }

      // 作者名による絞り込み
      if (filter.authorName != null && filter.authorName!.isNotEmpty) {
        filtered = filtered.where((s) => s.authorName == filter.authorName).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// 2. UIに渡す「表示用」リストのProvider (表示上限数でカット)
final displayedScenariosProvider = Provider<AsyncValue<List<Scenario>>>((ref) {
  final filteredAsync = ref.watch(_filteredAllScenariosProvider);
  final limit = ref.watch(searchScenariosViewModelProvider).displayLimit;

  return filteredAsync.whenData((scenarios) {
    if (scenarios.length > limit) {
      return scenarios.sublist(0, limit);
    }
    return scenarios;
  });
});

class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  Timer? _debounce;

  SearchScenariosViewModel() : super(SearchScenariosState());

  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(
        searchTerm: term,
        displayLimit: _kPageLimit, 
      );
    });
  }

  void applyFilter(SearchFilter newFilter) {
    state = state.copyWith(
      filter: newFilter,
      displayLimit: _kPageLimit,
    );
  }

  void loadMore() {
    state = state.copyWith(displayLimit: state.displayLimit + _kPageLimit);
  }

  void showSuccessMessage(String message) {
    state = state.copyWith(successMessage: message);
  }

  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
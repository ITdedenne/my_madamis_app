// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
// ★ 修正: UseCaseとProviderのインポートを削除
// ★ 修正: my_list_viewmodel.dart をインポート
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart'; 

// ★ 修正: getScenariosUseCaseProvider を削除

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
  // ★ 修正: isLoading, scenarios, pagination を削除
  final String? errorMessage;
  final String? successMessage;
  final SearchFilter filter;
  final String searchTerm; // ★ 検索クエリをStateで管理

  SearchScenariosState({
    this.errorMessage,
    this.successMessage,
    SearchFilter? filter,
    this.searchTerm = '',
  }) : filter = filter ?? SearchFilter.initial();

  SearchScenariosState copyWith({
    String? errorMessage,
    String? successMessage,
    SearchFilter? filter,
    String? searchTerm,
    // ★ 修正: null許容型に変更
    bool? isLoading,
    List<Scenario>? scenarios,
    int? currentPage,
    int? totalPages,
  }) {
    return SearchScenariosState(
      errorMessage: errorMessage,
      successMessage: successMessage,
      filter: filter ?? this.filter,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

// ★ 修正: ViewModelProvider の定義 (StateNotifierProvider)
final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  // ★ 修正: Usecaseの依存を削除
  return SearchScenariosViewModel();
});

// ★ 追加: フィルタリングされた結果を返す Provider
final filteredScenariosProvider = Provider<AsyncValue<List<Scenario>>>((ref) {
  // 1. S3からの全シナリオデータを監視
  final allScenariosAsync = ref.watch(allScenariosProvider);
  // 2. UIの検索/フィルター条件を監視
  final searchState = ref.watch(searchScenariosViewModelProvider);

  return allScenariosAsync.when(
    data: (allScenarios) {
      List<Scenario> filtered = allScenarios;

      // 3. クライアントサイド フィルタリング
      final filter = searchState.filter;
      final term = searchState.searchTerm.toLowerCase();
      
      // 3a. 検索
      if (term.isNotEmpty) {
        filtered = filtered.where((s) {
          return s.title.toLowerCase().contains(term) ||
                 s.authorName.toLowerCase().contains(term);
        }).toList();
      }
      
      // 3b. フィルター (人数)
      final start = filter.playerCountRange.start.round();
      final end = filter.playerCountRange.end.round();
      if (start > 1 || end < 15) {
         filtered = filtered.where((s) {
          // (min <= end) AND (max >= start)
          return s.minPlayerCount <= end && s.maxPlayerCount >= start;
        }).toList();
      }

      // 3c. フィルター (GM)
      if (filter.gmRequirement != null) {
        filtered = filtered.where((s) => s.gmRequirement == filter.gmRequirement).toList();
      }

      // 3d. フィルター (作者)
      if (filter.authorName != null && filter.authorName!.isNotEmpty) {
        filtered = filtered.where((s) => s.authorName == filter.authorName).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});


// ★ 修正: ViewModel は フィルター/検索クエリの "状態" のみを管理
class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  Timer? _debounce;
  // ★ 修正: Usecase と ページネーション関連の変数を削除

  // ★ 修正: Usecaseの依存を削除
  SearchScenariosViewModel() : super(SearchScenariosState()) {
    // ★ 修正: goToPage(1) の呼び出しを削除
  }

  // ★ 修正: ページネーション (goToPage) は削除

  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // APIコールはせず、Stateを更新するだけ
      state = state.copyWith(searchTerm: term);
    });
  }

  void applyFilter(SearchFilter newFilter) {
    // APIコールはせず、Stateを更新するだけ
    state = state.copyWith(filter: newFilter);
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
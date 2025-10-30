// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart
// 内容: 【修正】

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart';
import 'package:my_madamis_app/providers.dart';

// ★追加
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario_page.dart';


final getScenariosUseCaseProvider = Provider((ref) => GetScenariosUseCase(ref.watch(scenarioRepositoryProvider)));

// SearchFilter クラスは変更なし
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

// ★★★ SearchScenariosState を大幅に修正 ★★★
class SearchScenariosState {
  final bool isLoading;
  final String? errorMessage;
  final List<Scenario> scenarios; // 現在表示中のページのシナリオ
  final int currentPageIndex; // 0始まりのページインデックス
  
  // 各ページの *次* のトークンを保持するリスト
  // pageTokens[0] = 2ページ目のトークン
  // pageTokens[1] = 3ページ目のトークン
  final List<String?> pageTokens; 
  
  final String? successMessage;
  final SearchFilter filter;
  final String currentSearchTerm; // 検索クエリも状態として保持

  SearchScenariosState({
    this.isLoading = false,
    this.errorMessage,
    this.scenarios = const [],
    this.currentPageIndex = 0,
    this.pageTokens = const [], // 初期値は空リスト
    this.successMessage,
    SearchFilter? filter,
    this.currentSearchTerm = '',
  }) : filter = filter ?? SearchFilter.initial();

  SearchScenariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Scenario>? scenarios,
    int? currentPageIndex,
    List<String?>? pageTokens,
    String? successMessage,
    SearchFilter? filter,
    String? currentSearchTerm,
    bool? resetPagination, // ページネーションをリセットするフラグ
  }) {
    // ページネーションリセットがtrueの場合、関連する値を初期化
    final bool doReset = resetPagination ?? false;

    return SearchScenariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scenarios: doReset ? [] : (scenarios ?? this.scenarios),
      currentPageIndex: doReset ? 0 : (currentPageIndex ?? this.currentPageIndex),
      pageTokens: doReset ? [] : (pageTokens ?? this.pageTokens),
      successMessage: successMessage,
      filter: filter ?? this.filter,
      currentSearchTerm: currentSearchTerm ?? this.currentSearchTerm,
    );
  }
}

final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  final getScenarios = ref.watch(getScenariosUseCaseProvider);
  return SearchScenariosViewModel(getScenarios);
});

// ★★★ SearchScenariosViewModel を大幅に修正 ★★★
class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  final GetScenariosUseCase _getScenarios;
  Timer? _debounce;
  static const int _limit = 50; // 1ページの表示件数 (要件)

  SearchScenariosViewModel(this._getScenarios) : super(SearchScenariosState()) {
    goToPage(0); // 最初のページ (インデックス0) を読み込む
  }

  Future<void> goToPage(int pageIndex) async {
    state = state.copyWith(isLoading: true, currentPageIndex: pageIndex, errorMessage: null);
    
    // ページ1 (index 0) をリクエストする場合は token は null
    // ページ2 (index 1) をリクエストする場合は pageTokens[0] を使う
    final String? token = (pageIndex == 0) ? null : state.pageTokens[pageIndex - 1];

    try {
      final ScenarioPage result = await _getScenarios(
        nextToken: token,
        limit: _limit,
        searchTerm: state.currentSearchTerm.isEmpty ? null : state.currentSearchTerm,
        playerCountRange: state.filter.playerCountRange,
        gmRequirement: state.filter.gmRequirement,
        authorName: state.filter.authorName,
      );

      List<String?> newPageTokens = List.from(state.pageTokens);

      // ページトークンリストを更新
      if (pageIndex == newPageTokens.length) {
        // まだリストにない新しいページの結果の場合
        if (result.nextToken != null) {
          newPageTokens.add(result.nextToken); // 次のトークンを追加
        }
      } else {
        // 既存のページ (例: 1ページ目に戻る) の場合はトークンリストは変更しない
      }

      state = state.copyWith(
        isLoading: false,
        scenarios: result.scenarios,
        pageTokens: newPageTokens,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // 検索条件が変わったら、ページネーションをリセットして1ページ目から再検索
      state = state.copyWith(currentSearchTerm: term, resetPagination: true);
      goToPage(0);
    });
  }

  void applyFilter(SearchFilter newFilter) {
    // フィルターが変わったら、ページネーションをリセットして1ページ目から再検索
    state = state.copyWith(filter: newFilter, resetPagination: true);
    goToPage(0);
  }

  // --- メッセージ関連は変更なし ---
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
// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
// ★修正: UseCaseの戻り値型 ScenarioFetchResult をインポート
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart'; 
import 'package:my_madamis_app/providers.dart';

final getScenariosUseCaseProvider = Provider((ref) => GetScenariosUseCase(ref.watch(scenarioRepositoryProvider)));

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
  final bool isLoading;
  final String? errorMessage;
  final List<Scenario> scenarios;
  final int currentPage;
  final int totalPages;
  final String? successMessage;
  final SearchFilter filter;
  // nextTokenはViewModel内部で Map<_pageTokens> として管理するため、Stateから削除 (UIは直接使用しないため)
  // final String? nextToken; 

  SearchScenariosState({
    this.isLoading = false,
    this.errorMessage,
    this.scenarios = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.successMessage,
    SearchFilter? filter,
    // this.nextToken, // 削除
  }) : filter = filter ?? SearchFilter.initial();

  SearchScenariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Scenario>? scenarios,
    int? currentPage,
    int? totalPages,
    String? successMessage,
    SearchFilter? filter,
    bool resetPagination = false,
  }) {
    return SearchScenariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scenarios: scenarios ?? this.scenarios,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      successMessage: successMessage,
      filter: filter ?? this.filter,
      // nextTokenのロジックを削除
    );
  }
}

final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  final getScenarios = ref.watch(getScenariosUseCaseProvider);
  return SearchScenariosViewModel(getScenarios);
});

class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  final GetScenariosUseCase _getScenarios;
  Timer? _debounce;
  static const int _limit = 50;
  static const int _totalScenarios = 175; // 仮の合計シナリオ数 (修正済み)

  // ★★★ 修正: ページングの状態管理 (page number -> nextToken) ★★★
  Map<int, String?> _pageTokens = {}; 

  SearchScenariosViewModel(this._getScenarios) : super(SearchScenariosState()) {
    // totalPagesを初期化時に計算し、状態に含める
    final calculatedTotalPages = (_totalScenarios / _limit).ceil();
    state = state.copyWith(totalPages: calculatedTotalPages);
    
    // 初期ロード
    _pageTokens = {1: null}; // 1ページ目の開始トークンはnull
    goToPage(1);
  }

  Future<void> goToPage(int page, {String? searchTerm}) async {
    // ページング範囲チェック (totalPages <= page のチェックを緩和し、nextTokenがnullになるまで進める)
    if (page < 1 || (page > state.currentPage && !_pageTokens.containsKey(page))) {
        // 次のページボタンを押したが、トークンがなければ終了
        return;
    }

    // 読み込み中の場合は中断
    if (state.isLoading) return;
    
    // 取得開始トークンを設定
    final startToken = _pageTokens[page]; 

    state = state.copyWith(isLoading: true, currentPage: page, errorMessage: null);
    try {
      // ★★★ 修正: UseCaseの戻り値の型と引数に合わせる ★★★
      final result = await _getScenarios.call(
        page: page,
        limit: _limit,
        searchTerm: searchTerm,
        playerCountRange: state.filter.playerCountRange,
        gmRequirement: state.filter.gmRequirement,
        authorName: state.filter.authorName,
        startToken: startToken, 
      );
      
      // 次のページのトークンを保存
      final nextToken = result.nextToken;
      if (nextToken != null) {
          _pageTokens[page + 1] = nextToken;
      } else {
          // 次のページがない場合、総ページ数を更新
          _pageTokens.remove(page + 1);
      }
      
      // ★修正: nextTokenに基づいて totalPages を更新
      final actualTotalPages = nextToken == null ? page : state.totalPages;


      state = state.copyWith(
        isLoading: false,
        scenarios: result.scenarios,
        totalPages: actualTotalPages,
      );

    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // 検索・フィルタ変更時はページング情報をリセット
      _pageTokens = {1: null}; 
      final calculatedTotalPages = (_totalScenarios / _limit).ceil(); // 検索結果総数は不明だが、仮の最大値に戻す
      state = state.copyWith(totalPages: calculatedTotalPages, currentPage: 1, filter: state.filter, resetPagination: true); 
      goToPage(1, searchTerm: term);
    });
  }

  void applyFilter(SearchFilter newFilter) {
    // フィルタ変更時はページング情報をリセット
    _pageTokens = {1: null}; 
    final calculatedTotalPages = (_totalScenarios / _limit).ceil();
    state = state.copyWith(filter: newFilter, totalPages: calculatedTotalPages, currentPage: 1, resetPagination: true);
    goToPage(1);
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
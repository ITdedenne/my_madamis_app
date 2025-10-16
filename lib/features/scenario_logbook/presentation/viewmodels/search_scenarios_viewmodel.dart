// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
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

  SearchScenariosState({
    this.isLoading = false,
    this.errorMessage,
    this.scenarios = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.successMessage,
    SearchFilter? filter,
  }) : filter = filter ?? SearchFilter.initial();

  SearchScenariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Scenario>? scenarios,
    int? currentPage,
    int? totalPages,
    String? successMessage,
    SearchFilter? filter,
  }) {
    return SearchScenariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scenarios: scenarios ?? this.scenarios,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      successMessage: successMessage,
      filter: filter ?? this.filter,
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

  SearchScenariosViewModel(this._getScenarios) : super(SearchScenariosState()) {
    goToPage(1);
  }

  Future<void> goToPage(int page, {String? searchTerm}) async {
    state = state.copyWith(isLoading: true, currentPage: page, errorMessage: null);
    try {
      final newScenarios = await _getScenarios(
        page: page,
        limit: _limit,
        searchTerm: searchTerm,
        playerCountRange: state.filter.playerCountRange,
        gmRequirement: state.filter.gmRequirement,
        authorName: state.filter.authorName,
      );
      state = state.copyWith(
        isLoading: false,
        scenarios: newScenarios,
        totalPages: (175 / _limit).ceil(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      goToPage(1, searchTerm: term);
    });
  }

  void applyFilter(SearchFilter newFilter) {
    state = state.copyWith(filter: newFilter);
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
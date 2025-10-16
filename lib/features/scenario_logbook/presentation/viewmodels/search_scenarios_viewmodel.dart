// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/providers.dart';

class SearchScenariosState {
  final bool isLoading;
  final String? errorMessage;
  final List<Scenario> scenarios;
  final Map<String, UserScenarioStatus> myScenarioStatuses;
  final int currentPage;
  final int totalPages; // 総ページ数を保持

  SearchScenariosState({
    this.isLoading = false,
    this.errorMessage,
    this.scenarios = const [],
    this.myScenarioStatuses = const {},
    this.currentPage = 1,
    this.totalPages = 1,
  });

  SearchScenariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Scenario>? scenarios,
    Map<String, UserScenarioStatus>? myScenarioStatuses,
    int? currentPage,
    int? totalPages,
  }) {
    return SearchScenariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      scenarios: scenarios ?? this.scenarios,
      myScenarioStatuses: myScenarioStatuses ?? this.myScenarioStatuses,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  return SearchScenariosViewModel(ref.watch(scenarioRepositoryProvider));
});

class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  final ScenarioRepository _repository;
  Timer? _debounce;
  static const int _limit = 50;
  static const int _totalScenarios = 175; // データ総数をViewModelも知っておく

  SearchScenariosViewModel(this._repository) : super(SearchScenariosState()) {
    goToPage(1); // 初期表示は1ページ目
  }

  // 【変更点①】指定したページに移動するロジック
  Future<void> goToPage(int page, {String? searchTerm}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final newScenarios = await _repository.fetchScenarios(page: page, limit: _limit, searchTerm: searchTerm);
      state = state.copyWith(
        isLoading: false,
        scenarios: newScenarios,
        totalPages: (_totalScenarios / _limit).ceil(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      goToPage(1, searchTerm: term); // 検索時は1ページ目に戻る
    });
  }

  // 【変更点②】ステータス更新ロジック
  Future<void> updateStatus(String scenarioId, UserScenarioStatus newStatus) async {
    final originalStatuses = Map<String, UserScenarioStatus>.from(state.myScenarioStatuses);
    
    final newStatuses = Map<String, UserScenarioStatus>.from(state.myScenarioStatuses);
    if (newStatus.isUnregistered) {
      newStatuses.remove(scenarioId);
    } else {
      newStatuses[scenarioId] = newStatus;
    }
    state = state.copyWith(myScenarioStatuses: newStatuses);

    try {
      if (newStatus.isUnregistered) {
        await _repository.removeUserScenarioStatus(scenarioId);
      } else {
        await _repository.updateUserScenarioStatus(scenarioId, newStatus);
      }
    } catch (e) {
      state = state.copyWith(
        myScenarioStatuses: originalStatuses,
        errorMessage: '更新に失敗しました: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
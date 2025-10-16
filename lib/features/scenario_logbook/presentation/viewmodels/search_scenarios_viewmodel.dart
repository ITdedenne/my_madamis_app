// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_scenarios_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/providers.dart';

// UseCaseのProvider定義
final getScenariosUseCaseProvider = Provider((ref) => GetScenariosUseCase(ref.watch(scenarioRepositoryProvider)));
final updateUserScenarioStatusUseCaseProvider = Provider((ref) => UpdateUserScenarioStatusUseCase(ref.watch(scenarioRepositoryProvider)));

class SearchScenariosState {
  final bool isLoading;
  final String? errorMessage;
  final List<Scenario> scenarios;
  final Map<String, UserScenarioStatus> myScenarioStatuses;
  final int currentPage;
  final int totalPages;
  final String? successMessage; // SnackBar表示用

  SearchScenariosState({
    this.isLoading = false,
    this.errorMessage,
    this.scenarios = const [],
    this.myScenarioStatuses = const {},
    this.currentPage = 1,
    this.totalPages = 1,
    this.successMessage,
  });

  SearchScenariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Scenario>? scenarios,
    Map<String, UserScenarioStatus>? myScenarioStatuses,
    int? currentPage,
    int? totalPages,
    String? successMessage,
  }) {
    return SearchScenariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // nullを許容するため ?? this.errorMessage は使わない
      scenarios: scenarios ?? this.scenarios,
      myScenarioStatuses: myScenarioStatuses ?? this.myScenarioStatuses,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      successMessage: successMessage, // nullを許容
    );
  }
}

final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  final getScenarios = ref.watch(getScenariosUseCaseProvider);
  final updateUserStatus = ref.watch(updateUserScenarioStatusUseCaseProvider);
  return SearchScenariosViewModel(ref, getScenarios, updateUserStatus);
});

class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  final Ref _ref;
  final GetScenariosUseCase _getScenarios;
  final UpdateUserScenarioStatusUseCase _updateUserStatus;
  Timer? _debounce;
  static const int _limit = 50;
  static const int _totalScenarios = 175;

  SearchScenariosViewModel(this._ref, this._getScenarios, this._updateUserStatus) : super(SearchScenariosState()) {
    goToPage(1);
  }

  Future<void> goToPage(int page, {String? searchTerm}) async {
    state = state.copyWith(isLoading: true, currentPage: page, errorMessage: null);
    try {
      final newScenarios = await _getScenarios(page: page, limit: _limit, searchTerm: searchTerm);
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
      goToPage(1, searchTerm: term);
    });
  }

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
      await _updateUserStatus(scenarioId, newStatus);
      // ▼▼▼ 修正点: refreshの結果を未使用変数の `_` に代入 ▼▼▼
      final _ = _ref.refresh(myListViewModelProvider);
      state = state.copyWith(successMessage: '手帳を更新しました');
    } catch (e) {
      state = state.copyWith(
        myScenarioStatuses: originalStatuses,
        errorMessage: '更新に失敗しました: ${e.toString()}',
      );
    }
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
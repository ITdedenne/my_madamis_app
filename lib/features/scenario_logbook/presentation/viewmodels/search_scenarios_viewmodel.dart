// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';

import '../../../../providers.dart';

// NOTE: 本来はこのファイルを `providers.dart` に移管します。
// final scenarioRepositoryProvider = Provider<ScenarioRepository>((ref) => ScenarioRepositoryImpl());

// 状態クラス
class SearchScenariosState {
  final bool isLoading;
  final bool isFetchingNextPage;
  final String? errorMessage;
  final List<Scenario> scenarios;
  final Map<String, UserScenarioStatus> myScenarioStatuses;
  final int currentPage;
  final bool hasNextPage;

  // コンストラクタ: 各プロパティの初期値を設定
  SearchScenariosState({
    this.isLoading = false,
    this.isFetchingNextPage = false,
    this.errorMessage,
    this.scenarios = const [],
    this.myScenarioStatuses = const {},
    this.currentPage = 0,
    this.hasNextPage = true,
  });

  // copyWith: 一部のプロパティのみを変更した新しいインスタンスを生成
  SearchScenariosState copyWith({
    bool? isLoading,
    bool? isFetchingNextPage,
    String? errorMessage,
    List<Scenario>? scenarios,
    Map<String, UserScenarioStatus>? myScenarioStatuses,
    int? currentPage,
    bool? hasNextPage,
  }) {
    return SearchScenariosState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingNextPage: isFetchingNextPage ?? this.isFetchingNextPage,
      errorMessage: errorMessage ?? this.errorMessage,
      scenarios: scenarios ?? this.scenarios,
      myScenarioStatuses: myScenarioStatuses ?? this.myScenarioStatuses,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

// ViewModel
final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>((ref) {
  // NOTE: 本来はUseCaseを経由しますが、今回は直接Repositoryを呼び出します。
  // final getScenariosUseCase = GetScenariosUseCase(ref.watch(scenarioRepositoryProvider));
  // final updateUserScenarioUseCase = UpdateUserScenarioUseCase(ref.watch(scenarioRepositoryProvider));
  return SearchScenariosViewModel(ref.watch(scenarioRepositoryProvider));
});

class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  final ScenarioRepository _repository;
  Timer? _debounce;

  SearchScenariosViewModel(this._repository) : super(SearchScenariosState()) {
    // 初期データを読み込む
    fetchInitialScenarios();
  }

  // 1ページ目のデータを取得する
  Future<void> fetchInitialScenarios({String? searchTerm}) async {
    state = state.copyWith(isLoading: true, currentPage: 1, scenarios: []);
    try {
      final newScenarios = await _repository.fetchScenarios(page: 1, searchTerm: searchTerm);
      state = state.copyWith(
        isLoading: false,
        scenarios: newScenarios,
        hasNextPage: newScenarios.length == 50, // 50件未満なら次のページはない
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // 検索処理（0.5秒のdebounce付き）
  void onSearchTermChanged(String term) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchInitialScenarios(searchTerm: term);
    });
  }

  // 次のページのデータを取得する
  Future<void> fetchNextPage({String? searchTerm}) async {
    if (state.isFetchingNextPage || !state.hasNextPage) return;

    state = state.copyWith(isFetchingNextPage: true);
    final nextPage = state.currentPage + 1;
    try {
      final newScenarios = await _repository.fetchScenarios(page: nextPage, searchTerm: searchTerm);
      state = state.copyWith(
        isFetchingNextPage: false,
        scenarios: [...state.scenarios, ...newScenarios],
        currentPage: nextPage,
        hasNextPage: newScenarios.length == 50,
      );
    } catch (e) {
      state = state.copyWith(isFetchingNextPage: false, errorMessage: e.toString());
    }
  }

  // ステータスを更新し、UIに即時反映させる
  Future<void> updateStatus(String scenarioId, UserScenarioStatus? newStatus) async {
    final originalStatuses = Map<String, UserScenarioStatus>.from(state.myScenarioStatuses);
    
    // UIを即時反映
    final newStatuses = Map<String, UserScenarioStatus>.from(state.myScenarioStatuses);
    if (newStatus == null) {
      newStatuses.remove(scenarioId);
    } else {
      newStatuses[scenarioId] = newStatus;
    }
    state = state.copyWith(myScenarioStatuses: newStatuses);

    // データベースへの更新処理
    try {
      if (newStatus == null) {
        await _repository.removeUserScenarioStatus(scenarioId);
      } else {
        await _repository.updateUserScenarioStatus(scenarioId, newStatus);
      }
    } catch (e) {
      // エラーが発生した場合はUIを元に戻す
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
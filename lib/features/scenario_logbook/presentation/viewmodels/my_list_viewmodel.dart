// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/repositories/scenario_repository.dart';
import 'package:my_madamis_app/providers.dart'; // `scenarioRepositoryProvider` を使うためにimport

// マイリスト画面の状態を管理するクラス
class MyListState {
  final bool isLoading;
  final String? errorMessage;
  final List<UserScenario> userScenarios;

  MyListState({
    this.isLoading = false,
    this.errorMessage,
    this.userScenarios = const [],
  });

  MyListState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UserScenario>? userScenarios,
  }) {
    return MyListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      userScenarios: userScenarios ?? this.userScenarios,
    );
  }
}

// ViewModelのProvider
final myListViewModelProvider = StateNotifierProvider<MyListViewModel, MyListState>((ref) {
  // NOTE: 本来はUseCaseを経由しますが、今回は直接Repositoryを呼び出します。
  return MyListViewModel(ref.watch(scenarioRepositoryProvider));
});

// ViewModel本体
class MyListViewModel extends StateNotifier<MyListState> {
  final ScenarioRepository _repository;

  MyListViewModel(this._repository) : super(MyListState()) {
    fetchMyList();
  }

  // マイリストのデータを取得・更新する
  Future<void> fetchMyList() async {
    state = state.copyWith(isLoading: true);
    try {
      final myList = await _repository.fetchMyList();
      state = state.copyWith(isLoading: false, userScenarios: myList);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
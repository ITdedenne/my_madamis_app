// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/providers.dart';

// UseCaseのProvider
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));

// フィルターの状態を表すEnum
enum MyListFilter { all, played, possessed }

class MyListState {
  final bool isLoading;
  final String? errorMessage;
  final List<UserScenario> allUserScenarios;
  final MyListFilter filter;

  MyListState({
    this.isLoading = false,
    this.errorMessage,
    this.allUserScenarios = const [],
    this.filter = MyListFilter.all,
  });

  // フィルターされたリストを返すgetter
  List<UserScenario> get filteredScenarios {
    switch (filter) {
      case MyListFilter.played:
        return allUserScenarios.where((s) => s.status.isPlayed).toList();
      case MyListFilter.possessed:
        return allUserScenarios.where((s) => s.status.isPossessed).toList();
      case MyListFilter.all:
        return allUserScenarios;
    }
  }

  MyListState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UserScenario>? allUserScenarios,
    MyListFilter? filter,
  }) {
    return MyListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      allUserScenarios: allUserScenarios ?? this.allUserScenarios,
      filter: filter ?? this.filter,
    );
  }
}

final myListViewModelProvider = StateNotifierProvider<MyListViewModel, MyListState>((ref) {
  return MyListViewModel(ref.watch(getMyListUseCaseProvider));
});

class MyListViewModel extends StateNotifier<MyListState> {
  final GetMyListUseCase _getMyList;

  MyListViewModel(this._getMyList) : super(MyListState()) {
    fetchMyList();
  }

  Future<void> fetchMyList() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final myList = await _getMyList();
      state = state.copyWith(isLoading: false, allUserScenarios: myList);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
  
  void setFilter(MyListFilter newFilter) {
    state = state.copyWith(filter: newFilter);
  }
}
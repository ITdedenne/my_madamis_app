// ファイルパス: lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/providers.dart';

// UseCaseのProvider
final getMyListUseCaseProvider = Provider((ref) => GetMyListUseCase(ref.watch(scenarioRepositoryProvider)));

// フィルターの状態を表すEnum
enum MyListFilter { all, played, possessed }

// 並び替え順のenum
enum SortOrder { byTitle, byAuthor }

class MyListState {
  final bool isLoading;
  final String? errorMessage;
  final List<UserScenario> allUserScenarios;
  final MyListFilter filter;
  final SortOrder sortOrder;

  MyListState({
    this.isLoading = false,
    this.errorMessage,
    this.allUserScenarios = const [],
    this.filter = MyListFilter.all,
    this.sortOrder = SortOrder.byTitle,
  });

  List<UserScenario> get filteredAndSortedScenarios {
    List<UserScenario> filtered;
    switch (filter) {
      case MyListFilter.played:
        filtered = allUserScenarios.where((s) => s.status.isPlayed).toList();
        break;
      case MyListFilter.possessed:
        filtered = allUserScenarios.where((s) => s.status.isPossessed).toList();
        break;
      case MyListFilter.all:
        filtered = allUserScenarios;
        break;
    }
    
    // 並び替え処理
    filtered.sort((a, b) {
      switch (sortOrder) {
        case SortOrder.byTitle:
          return a.scenario.title.compareTo(b.scenario.title);
        case SortOrder.byAuthor:
          return a.scenario.authorName.compareTo(b.scenario.authorName);
      }
    });
    return filtered;
  }

  MyListState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UserScenario>? allUserScenarios,
    MyListFilter? filter,
    SortOrder? sortOrder,
  }) {
    return MyListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      allUserScenarios: allUserScenarios ?? this.allUserScenarios,
      filter: filter ?? this.filter,
      sortOrder: sortOrder ?? this.sortOrder,
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

  void setSortOrder(SortOrder newOrder) {
    state = state.copyWith(sortOrder: newOrder);
  }
}
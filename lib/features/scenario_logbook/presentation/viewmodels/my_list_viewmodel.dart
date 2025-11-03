// lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// (MyListFilter, myListFilterProvider は変更なし)
enum MyListFilter { all, played, possessed }
final myListFilterProvider =
    StateProvider<MyListFilter>((ref) => MyListFilter.all);

// (MyListSortOrder, myListSortProvider は変更なし)
enum MyListSortOrder { dateAdded, titleAsc }
final myListSortProvider =
    StateProvider<MyListSortOrder>((ref) => MyListSortOrder.dateAdded);

// (MyListViewState クラスは変更なし)
class MyListViewState {
  final AsyncValue<List<ScenarioLogbookEntry>> scenarios;

  MyListViewState({
    this.scenarios = const AsyncValue.loading(),
  });

  MyListViewState copyWith({
    AsyncValue<List<ScenarioLogbookEntry>>? scenarios,
  }) {
    return MyListViewState(
      scenarios: scenarios ?? this.scenarios,
    );
  }
}

// StateNotifier
class MyListViewModel extends StateNotifier<MyListViewState> {
  MyListViewModel(this._ref) : super(MyListViewState()) {
    fetch(); // 初期化時にデータを取得
  }

  final Ref _ref;

  // (fetch メソッドは変更なし)
  Future<void> fetch() async {
    state = state.copyWith(scenarios: const AsyncValue.loading());
    try {
      final authState = _ref.read(authStateNotifierProvider);
      final userId = authState.username; 
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final getMyListUsecase = _ref.read(getMyListUsecaseProvider);
      final data = await getMyListUsecase(userId);
      
      // (createdAt/updatedAt が無いモデルのため、ソートロジックは削除したまま)
      
      state = state.copyWith(scenarios: AsyncValue.data(data));
    } catch (e, s) {
      state = state.copyWith(scenarios: AsyncValue.error(e, s));
    }
  }

  // --- ▼ 修正 ▼ ---
  // ステータスを更新するメソッド (オプティミスティック・アップデート)
  Future<void> updateScenarioStatus(
      String scenarioId, bool isPlayed, bool isPossessed) async {
    final userId = _ref.read(authStateNotifierProvider).username;
    if (userId == null) return;

    final usecase = _ref.read(updateUserScenarioStatusUsecaseProvider);

    // 1. UI（ローカル状態）を即座に更新する
    // (ScenarioLogbookEntry.dart に copyWith が無いため、手動で再生成)
    state = state.scenarios.when(
      data: (scenarios) {
        final newList = scenarios.map((item) {
          if (item.id == scenarioId) {
            // 新しいオブジェクトを生成
            return ScenarioLogbookEntry(
              id: item.id,
              title: item.title,
              minPlayerCount: item.minPlayerCount,
              maxPlayerCount: item.maxPlayerCount,
              gmRequirement: item.gmRequirement,
              storeUrl: item.storeUrl,
              authorId: item.authorId,
              authorName: item.authorName,
              createdAt: item.createdAt, // タイムスタンプもコピー
              updatedAt: item.updatedAt, // タイムスタンプもコピー
              // 更新されたステータス
              isPlayed: isPlayed,
              isPossessed: isPossessed,
            );
          }
          return item;
        }).toList();
        // 新しいリストで state を更新
        return state.copyWith(scenarios: AsyncValue.data(newList));
      },
      loading: () => state,
      error: (e, s) => state,
    );


    try {
      // 2. バックグラウンドで DataStore の更新を実行
      await usecase.call( 
        userId: userId,
        scenarioId: scenarioId,
        isPlayed: isPlayed,
        isPossessed: isPossessed,
      );
      // (Search 側への通知は不要)

    } catch (e) {
      // 3. もし DataStore への保存が失敗したら、
      //    クラウドの最新情報でUIを元に戻す（ロールバック）
      await fetch();
    }
  }
  // --- ▲ 修正 ▲ ---
}

// (myListViewModelProvider は変更なし)
final myListViewModelProvider =
    StateNotifierProvider<MyListViewModel, MyListViewState>(
  (ref) => MyListViewModel(ref),
);

// (filteredMyListProvider は変更なし)
final filteredMyListProvider = Provider<List<ScenarioLogbookEntry>>((ref) {
  final state = ref.watch(myListViewModelProvider);
  final filter = ref.watch(myListFilterProvider);
  final sortOrder = ref.watch(myListSortProvider);

  return state.scenarios.when(
    data: (data) {
      // フィルタリング
      final filteredList = data.where((item) {
        switch (filter) {
          case MyListFilter.all:
            return true;
          case MyListFilter.played:
            return item.isPlayed;
          case MyListFilter.possessed:
            return item.isPossessed;
        }
      }).toList();

      // 並び替え (要件 1.2.7)
      if (sortOrder == MyListSortOrder.titleAsc) {
        filteredList.sort((a, b) => a.title.compareTo(b.title));
      }
      
      return filteredList;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
// lib/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/update_user_scenario_status_usecase.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// マイリストのフィルタ状態
enum MyListFilter { all, played, possessed }

// フィルタ状態を管理するProvider
final myListFilterProvider =
    StateProvider<MyListFilter>((ref) => MyListFilter.all);

// マイリストのソート順 (要件 1.2.7)
enum MyListSortOrder { dateAdded, titleAsc }

// ソート順を管理するProvider
final myListSortProvider =
    StateProvider<MyListSortOrder>((ref) => MyListSortOrder.dateAdded);


// StateNotifier の状態クラス
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

  // データ取得
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
      
      // --- ▼ 修正 ▼ ---
      // エラーが出るため、 createdAt / updatedAt でのソートロジックを削除します。
      // APIの返却順（デフォルト）を「登録順」とみなします。
      // data.sort((a, b) => (b.updatedAt ?? b.createdAt!)
      //     .compareTo(a.updatedAt ?? a.createdAt!));
      // --- ▲ 修正 ▲ ---
      
      state = state.copyWith(scenarios: AsyncValue.data(data));
    } catch (e, s) {
      state = state.copyWith(scenarios: AsyncValue.error(e, s));
    }
  }

  // ステータスを更新するメソッド
  Future<void> updateScenarioStatus(
      String scenarioId, bool isPlayed, bool isPossessed) async {
    final userId = _ref.read(authStateNotifierProvider).username;
    if (userId == null) return;

    final usecase = _ref.read(updateUserScenarioStatusUsecaseProvider);

    try {
      await usecase.call( 
        userId: userId,
        scenarioId: scenarioId,
        isPlayed: isPlayed,
        isPossessed: isPossessed,
      );
      // データを再フェッチ
      await fetch();
    } catch (e) {
      // エラーハンドリング (例: スナックバー表示)
    }
  }
}

// StateNotifierProvider
final myListViewModelProvider =
    StateNotifierProvider<MyListViewModel, MyListViewState>(
  (ref) => MyListViewModel(ref),
);

// フィルタリング・ソート済みのリストを提供するProvider
final filteredMyListProvider = Provider<List<ScenarioLogbookEntry>>((ref) {
  // 元データを監視
  final state = ref.watch(myListViewModelProvider);
  // フィルタを監視
  final filter = ref.watch(myListFilterProvider);
  // ソート順を監視 (要件 1.2.7)
  final sortOrder = ref.watch(myListSortProvider);

  // AsyncValue.when を使って安全にデータを取り出す
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
      // dateAdded は fetch 時にソート済み（削除した）のため、何もしない (APIの返却順)
      
      return filteredList;
    },
    loading: () => [], // ローディング中は空リスト
    error: (e, s) => [], // エラー時も空リスト
  );
});
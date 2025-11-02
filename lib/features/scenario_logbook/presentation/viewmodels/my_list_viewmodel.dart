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
      final user = authState.cognitoUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final getMyListUsecase = _ref.read(getMyListUsecaseProvider);
      final data = await getMyListUsecase(user.userId);
      state = state.copyWith(scenarios: AsyncValue.data(data));
    } catch (e, s) {
      state = state.copyWith(scenarios: AsyncValue.error(e, s));
    }
  }

  // ステータスを更新するメソッド
  Future<void> updateScenarioStatus(
      String scenarioId, bool isPlayed, bool isPossessed) async {
    final user = _ref.read(authStateNotifierProvider).cognitoUser;
    if (user == null) return;

    final usecase = _ref.read(updateUserScenarioStatusUsecaseProvider);

    try {
      await usecase(
        userId: user.userId,
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

      // TODO: 必要に応じてソート順プロバイダを追加し、ここでソートロジックを実装
      // (例: タイトル順)
      // filteredList.sort((a, b) => a.title.compareTo(b.title));
      
      return filteredList;
    },
    loading: () => [], // ローディング中は空リスト
    error: (e, s) => [], // エラー時も空リスト
  );
});
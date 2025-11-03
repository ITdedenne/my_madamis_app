// lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';

// (SearchFilterState クラスは変更なし)
class SearchFilterState {
  final String? keyword;
  final int? minPlayerCount;
  final int? maxPlayerCount;

  SearchFilterState({
    this.keyword,
    this.minPlayerCount,
    this.maxPlayerCount,
  });

  SearchFilterState copyWith({
    String? keyword,
    int? minPlayerCount,
    int? maxPlayerCount,
  }) {
    return SearchFilterState(
      keyword: keyword ?? this.keyword,
      minPlayerCount: minPlayerCount ?? this.minPlayerCount,
      maxPlayerCount: maxPlayerCount ?? this.maxPlayerCount,
    );
  }

  Map<String, dynamic>? toFilterMap() {
    final Map<String, dynamic> filter = {};

    if (keyword != null && keyword!.isNotEmpty) {
      filter['or'] = [
        {'title': {'contains': keyword}},
        {'author': {'authorName': {'contains': keyword}}},
      ];
    }
    
    if (minPlayerCount != null) {
      filter['minPlayerCount'] = {'ge': minPlayerCount};
    }
    if (maxPlayerCount != null) {
      filter['maxPlayerCount'] = {'le': maxPlayerCount};
    }

    return filter.isEmpty ? null : filter;
  }
}

// (searchFilterProvider は変更なし)
final searchFilterProvider =
    StateProvider<SearchFilterState>((ref) => SearchFilterState());

// (SearchScenariosState クラスは変更なし)
class SearchScenariosState {
  final AsyncValue<List<ScenarioWithMyStatus>> scenarios;
  final String? nextToken;

  SearchScenariosState({
    this.scenarios = const AsyncValue.loading(),
    this.nextToken,
  });

  SearchScenariosState copyWith({
    AsyncValue<List<ScenarioWithMyStatus>>? scenarios,
    String? nextToken,
  }) {
    return SearchScenariosState(
      scenarios: scenarios ?? this.scenarios,
      nextToken: nextToken ?? this.nextToken,
    );
  }
}


// StateNotifier
class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  SearchScenariosViewModel(this._ref) : super(SearchScenariosState()) {
    _ref.listen<SearchFilterState>(searchFilterProvider, (_, __) {
      fetch();
    });
    fetch(); 
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

      final filterState = _ref.read(searchFilterProvider);
      final getScenariosUsecase = _ref.read(getScenariosUsecaseProvider);

      final connection = await getScenariosUsecase(
        filter: filterState.toFilterMap(),
        limit: 50,
        nextToken: state.nextToken,
      );

      state = state.copyWith(
        scenarios: AsyncValue.data(connection.items ?? []), 
        nextToken: connection.nextToken,
      );
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
    // (ScenarioWithMyStatus.dart に copyWith が無いため、手動で再生成)
    state = state.scenarios.when(
      data: (scenarios) {
        final newList = scenarios.map((item) {
          if (item.id == scenarioId) {
            // 新しいオブジェクトを生成
            return ScenarioWithMyStatus(
              id: item.id,
              title: item.title,
              minPlayerCount: item.minPlayerCount,
              maxPlayerCount: item.maxPlayerCount,
              gmRequirement: item.gmRequirement,
              storeUrl: item.storeUrl,
              authorId: item.authorId,
              author: item.author,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
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
      // ローディング中やエラー時は何もしない
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

      // 3. マイリスト側も更新を反映させるために再フェッチをキック
      // (MyList は DataStore ではなく Lambda を見ているため)
      _ref.read(myListViewModelProvider.notifier).fetch();

    } catch (e) {
      // 4. もし DataStore への保存が失敗したら、
      //    クラウドの最新情報でUIを元に戻す（ロールバック）
      await fetch();
    }
  }
  // --- ▲ 修正 ▲ ---
}

// (StateNotifierProvider は変更なし)
final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>(
  (ref) => SearchScenariosViewModel(ref),
);
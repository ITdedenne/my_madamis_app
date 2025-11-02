// lib/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
import 'package:my_madamis_app/providers.dart';
// import 'package:my_madamis_app/features/scenario_logbook/domain/usecases/get_my_list_usecase.dart'; // <-- Unused importのため削除

// 検索・フィルタ条件を保持するデータクラス
class SearchFilterState {
  final String? keyword;
  final int? minPlayerCount;
  final int? maxPlayerCount;
  // TODO: 他のフィルタ条件（時間、GM要件など）もここに追加

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

  // Amplifyの filter マップに変換
  Map<String, dynamic>? toFilterMap() {
    final Map<String, dynamic> filter = {};

    // キーワード検索 (タイトル or 作者名)
    if (keyword != null && keyword!.isNotEmpty) {
      filter['or'] = [
        {'title': {'contains': keyword}},
        {'author': {'authorName': {'contains': keyword}}},
      ];
    }
    
    // 人数
    if (minPlayerCount != null) {
      filter['minPlayerCount'] = {'ge': minPlayerCount};
    }
    if (maxPlayerCount != null) {
      filter['maxPlayerCount'] = {'le': maxPlayerCount};
    }

    // TODO: 他のフィルタ条件もここに追加

    return filter.isEmpty ? null : filter;
  }
}

// フィルタ状態を管理するProvider
final searchFilterProvider =
    StateProvider<SearchFilterState>((ref) => SearchFilterState());

// StateNotifier の状態クラス
class SearchScenariosState {
  final AsyncValue<List<Scenario>> scenarios;
  // TODO: ページネーション用の nextToken をここに保持
  // final String? nextToken;

  SearchScenariosState({
    this.scenarios = const AsyncValue.loading(),
    // this.nextToken,
  });

  SearchScenariosState copyWith({
    AsyncValue<List<Scenario>>? scenarios,
    // String? nextToken,
  }) {
    return SearchScenariosState(
      scenarios: scenarios ?? this.scenarios,
      // nextToken: nextToken ?? this.nextToken,
    );
  }
}

// StateNotifier
class SearchScenariosViewModel extends StateNotifier<SearchScenariosState> {
  SearchScenariosViewModel(this._ref) : super(SearchScenariosState()) {
    // フィルタ条件が変更されたら自動でフェッチする
    _ref.listen<SearchFilterState>(searchFilterProvider, (_, __) {
      fetch();
    });
    fetch(); // 初期データ取得
  }

  final Ref _ref;

  // データ取得
  Future<void> fetch() async {
    state = state.copyWith(scenarios: const AsyncValue.loading());
    try {
      final authState = _ref.read(authStateNotifierProvider);
      // 'user' ではなく 'username' を参照
      final userId = authState.username; 
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 現在のフィルタ条件を取得
      final filterState = _ref.read(searchFilterProvider);
      final getScenariosUsecase = _ref.read(getScenariosUsecaseProvider);

      // BEにクエリ実行
      final connection = await getScenariosUsecase(
        userId: userId, // 取得した userId (username) を渡す
        filter: filterState.toFilterMap(),
        limit: 50, // ページネーション (まずは50件)
      );

      state = state.copyWith(
        // 'List<...>?' can't be assigned エラーを修正
        scenarios: AsyncValue.data([]), 
        // nextToken: connection.nextToken,
      );
    } catch (e, s) {
      state = state.copyWith(scenarios: AsyncValue.error(e, s));
    }
  }

  // ステータスを更新するメソッド
  Future<void> updateScenarioStatus(
      String scenarioId, bool isPlayed, bool isPossessed) async {
    // 'user' ではなく 'username' を参照
    final userId = _ref.read(authStateNotifierProvider).username;
    if (userId == null) return;

    final usecase = _ref.read(updateUserScenarioStatusUsecaseProvider);

    try {
      await usecase.call( 
        userId: userId, // 取得した userId (username) を渡す
        scenarioId: scenarioId,
        isPlayed: isPlayed,
        isPossessed: isPossessed,
      );

      // データを再フェッチ
      await fetch();
      
      // マイリスト側も更新を反映させるために再フェッチをキック
      _ref.read(myListViewModelProvider.notifier).fetch();

    } catch (e) {
      // エラーハンドリング
    }
  }
}

// StateNotifierProvider
final searchScenariosViewModelProvider =
    StateNotifierProvider<SearchScenariosViewModel, SearchScenariosState>(
  (ref) => SearchScenariosViewModel(ref),
);
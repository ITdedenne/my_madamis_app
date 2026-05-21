import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';

void main() {
  // テスト用データ
  final mockScenarios = [
    Scenario(
      id: '1',
      title: 'ミステリー・ハウス',
      authorName: '田中',
      authorId: 'auth_1',
      minPlayerCount: 2,
      maxPlayerCount: 4,
      gmRequirement: GmRequirement.required,
      titleLower: 'ミステリー・ハウス',
      authorNameLower: '田中',
    ),
    Scenario(
      id: '2',
      title: '冒険の書',
      authorName: '佐藤',
      authorId: 'auth_2',
      minPlayerCount: 3,
      maxPlayerCount: 5,
      gmRequirement: GmRequirement.optional,
      titleLower: '冒険の書',
      authorNameLower: '佐藤',
    ),
  ];

  test('ViewModelの初期状態が正しく設定されていること', () {
    final container = ProviderContainer();
    final state = container.read(searchScenariosViewModelProvider);

    expect(state.searchTerm, '');
    expect(state.filter.isInitial, isTrue);
    expect(state.displayLimit, 48);
  });

  test('検索ワードの変更時、正しく状態が更新されること', () async {
    final container = ProviderContainer(overrides: [
      allScenariosProvider.overrideWith((ref) => Future.value(mockScenarios)),
    ]);
    final viewModel = container.read(searchScenariosViewModelProvider.notifier);

    viewModel.onSearchTermChanged('ミステリー');

    // Debounce処理を待つ
    await Future.delayed(const Duration(milliseconds: 350));

    final state = container.read(searchScenariosViewModelProvider);
    expect(state.searchTerm, 'ミステリー');
  });

  test('フィルター適用時に状態が更新され、上限がリセットされること', () {
    final container = ProviderContainer();
    final viewModel = container.read(searchScenariosViewModelProvider.notifier);
    
    // フィルターの適用
    final newFilter = SearchFilter(
      playerCountRange: const RangeValues(3, 5),
      gmRequirement: GmRequirement.optional,
    );

    viewModel.applyFilter(newFilter);

    final state = container.read(searchScenariosViewModelProvider);
    expect(state.filter.playerCountRange.start, 3);
    expect(state.filter.gmRequirement, GmRequirement.optional);
    expect(state.displayLimit, 48);
  });

  test('loadMore実行時に表示上限が増加すること', () {
    final container = ProviderContainer();
    final viewModel = container.read(searchScenariosViewModelProvider.notifier);

    viewModel.loadMore();

    final state = container.read(searchScenariosViewModelProvider);
    expect(state.displayLimit, 96);
  });
}
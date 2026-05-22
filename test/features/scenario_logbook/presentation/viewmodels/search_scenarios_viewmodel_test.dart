import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';

void main() {
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
    Scenario(
      id: '3',
      title: 'ホラーミステリー',
      authorName: '鈴木',
      authorId: 'auth_3',
      minPlayerCount: 5,
      maxPlayerCount: 7,
      gmRequirement: GmRequirement.none, 
      titleLower: 'ホラーミステリー',
      authorNameLower: '鈴木',
    ),
  ];

  group('SearchScenariosViewModel & Providers', () {
    test('【正常系】ViewModelの初期状態が正しく設定されていること', () {
      final container = ProviderContainer();
      final state = container.read(searchScenariosViewModelProvider);

      expect(state.searchTerm, '');
      expect(state.filter.isInitial, isTrue);
      expect(state.displayLimit, 48);
    });

    test('【正常系】検索ワード（AND検索・大文字小文字無視・全角スペース対応）で正しく絞り込めること', () async {
      final container = ProviderContainer(overrides: [
        allScenariosProvider.overrideWith((ref) async => mockScenarios),
      ]);
      await container.read(allScenariosProvider.future);

      final viewModel = container.read(searchScenariosViewModelProvider.notifier);

      viewModel.onSearchTermChanged('ミステリー　田中');
      await Future.delayed(const Duration(milliseconds: 350)); // Debounce待機

      final displayedAsync = container.read(displayedScenariosProvider);
      
      expect(displayedAsync.hasValue, isTrue);
      final list = displayedAsync.value!;
      expect(list.length, 1);
      expect(list.first.id, '1');
    });

    test('【正常系】プレイ人数とGM要否で正しく絞り込めること', () async {
      final container = ProviderContainer(overrides: [
        allScenariosProvider.overrideWith((ref) async => mockScenarios),
      ]);
      await container.read(allScenariosProvider.future);

      final viewModel = container.read(searchScenariosViewModelProvider.notifier);

      viewModel.applyFilter(SearchFilter(
        playerCountRange: const RangeValues(5, 5),
        gmRequirement: GmRequirement.none,
      ));

      final displayedAsync = container.read(displayedScenariosProvider);
      expect(displayedAsync.hasValue, isTrue);
      
      final list = displayedAsync.value!;
      expect(list.length, 1);
      expect(list.first.id, '3');
    });

    test('【正常系】作者名で正しく絞り込めること', () async {
      final container = ProviderContainer(overrides: [
        allScenariosProvider.overrideWith((ref) async => mockScenarios),
      ]);
      await container.read(allScenariosProvider.future);

      final viewModel = container.read(searchScenariosViewModelProvider.notifier);

      viewModel.applyFilter(SearchFilter(
        playerCountRange: const RangeValues(1, 15),
        authorName: '佐藤',
      ));

      final displayedAsync = container.read(displayedScenariosProvider);
      expect(displayedAsync.hasValue, isTrue);

      final list = displayedAsync.value!;
      expect(list.length, 1);
      expect(list.first.id, '2');
    });

    test('【正常系】loadMore実行時に表示上限が増加し、正しいリスト件数が返ること', () async {
      final largeMockList = List.generate(50, (index) => Scenario(
        id: 'id_$index',
        title: 'Title $index',
        authorName: 'Author',
        authorId: 'auth',
        minPlayerCount: 4,
        maxPlayerCount: 4,
        gmRequirement: GmRequirement.required,
        titleLower: 'title $index',
        authorNameLower: 'author',
      ));

      final container = ProviderContainer(overrides: [
        allScenariosProvider.overrideWith((ref) async => largeMockList),
      ]);

      await container.read(allScenariosProvider.future);
      
      var displayedAsync = container.read(displayedScenariosProvider);
      expect(displayedAsync.hasValue, isTrue);
      expect(displayedAsync.value!.length, 48);

      container.read(searchScenariosViewModelProvider.notifier).loadMore();
      
      displayedAsync = container.read(displayedScenariosProvider);
      expect(displayedAsync.value!.length, 50);
    });

test('【異常系】大元のデータ取得でエラーが発生した場合、エラー状態になること', () async {
      final container = ProviderContainer(overrides: [
        allScenariosProvider.overrideWith((ref) async => throw Exception('ネットワークエラーが発生しました')),
      ]);

      try {
        await container.read(allScenariosProvider.future);
      } catch (_) {
        // エラーがスローされるのは想定通りなので、ここでキャッチしてテストが落ちるのを防ぐ
      }

      final displayedAsync = container.read(displayedScenariosProvider);

      expect(displayedAsync.hasError, isTrue);
      expect(displayedAsync.error.toString(), contains('ネットワークエラーが発生しました'));
    });
  });
}
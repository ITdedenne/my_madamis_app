import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/my_list_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

void main() {
  final tUserScenario = UserScenario(
    scenario: Scenario(
      id: '1',
      title: 'テストシナリオ',
      authorName: 'テスト作者',
      authorId: 'auth1',
      minPlayerCount: 4,
      maxPlayerCount: 4,
      gmRequirement: GmRequirement.required,
      titleLower: 'テストシナリオ',
      authorNameLower: 'テストさくしゃ',
    ),
    status: const UserScenarioStatus(isPlayed: true),
  );

  // テスト対象のページを生成するヘルパー関数
  Widget createPageUnderTest(AsyncValue<List<UserScenario>> mockState) {
    return ProviderScope(
      overrides: [
        // ViewModel(Provider) の戻り値をモック状態に強制上書きする
        filteredAndSortedMyListProvider.overrideWithValue(mockState),
      ],
      child: const MaterialApp(
        home: MyListPage(),
      ),
    );
  }

  group('MyListPage UI Test', () {
    testWidgets('【正常系】ローディング中はインジケーターが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(createPageUnderTest(const AsyncValue.loading()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('【正常系】データが空の場合は、空である旨のメッセージが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(createPageUnderTest(const AsyncValue.data([])));
      await tester.pumpAndSettle();

      expect(find.textContaining('記録されたシナリオはありません'), findsOneWidget); 
      expect(find.byType(ScenarioListItem), findsNothing);
    });

    testWidgets('【正常系】データが存在する場合は、ScenarioListItemがレンダリングされること', (WidgetTester tester) async {
      await tester.pumpWidget(createPageUnderTest(AsyncValue.data([tUserScenario])));
      await tester.pumpAndSettle();

      expect(find.byType(ScenarioListItem), findsOneWidget);
      expect(find.text('テストシナリオ'), findsOneWidget);
    });

    testWidgets('【異常系】エラーが発生した場合は、エラーメッセージが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(createPageUnderTest(
        const AsyncValue.error('ネットワークエラーが発生しました', StackTrace.empty)
      ));
      await tester.pumpAndSettle();

      // エラー文言が表示されているか確認
      expect(find.textContaining('エラー'), findsOneWidget);
    });
  });
}
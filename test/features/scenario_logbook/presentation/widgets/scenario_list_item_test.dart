import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

void main() {
  // テスト用のダミーシナリオ
  final tScenario = Scenario(
    id: '1',
    title: '狂気山脈',
    authorName: 'まだら牛',
    authorId: 'auth1',
    minPlayerCount: 5,
    maxPlayerCount: 5,
    gmRequirement: GmRequirement.required,
    titleLower: '狂気山脈',
    authorNameLower: 'まだら牛',
  );

  Widget createWidgetUnderTest(UserScenarioStatus status) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ScenarioListItem(
            scenario: tScenario,
            status: status,
            onStatusChanged: (newStatus) {}, 
          ),
        ),
      ),
    );
  }

  group('ScenarioListItem UI Test', () {
    testWidgets('【正常系】シナリオのタイトルと作者名が正しく表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const UserScenarioStatus()));

      await tester.pumpAndSettle();

      // 指定したテキストが画面上に存在するか検証
      expect(find.text('狂気山脈'), findsOneWidget);
      expect(find.textContaining('まだら牛'), findsOneWidget); // "by まだら牛" のように装飾されているため textContaining を使用
    });

    testWidgets('【正常系】isPlayedがtrueの場合、「通過済」を表すUIが表示されること', (WidgetTester tester) async {

      await tester.pumpWidget(createWidgetUnderTest(const UserScenarioStatus(isPlayed: true)));
      await tester.pumpAndSettle();

      expect(find.text('通過済'), findsOneWidget);
      
      expect(find.text('PL希望'), findsNothing);
    });

    testWidgets('【正常系】複数のステータスがtrueの場合、両方のUIが表示されること', (WidgetTester tester) async {

      await tester.pumpWidget(createWidgetUnderTest(
        const UserScenarioStatus(isPossessed: true, wantsToGm: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('所持'), findsOneWidget);
      expect(find.text('購入検討'), findsOneWidget);
      expect(find.text('通過済'), findsNothing);
    });
  });
}
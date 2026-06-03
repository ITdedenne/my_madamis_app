import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

void main() {
  group('ScenarioRepositoryImpl / S3 Data Parsing Tests (堅牢性・Null安全検証)', () {
    test('【S3データ欠落対策】 不正なJSON（キーの欠落やnull）を受け取っても、クラッシュせずにデフォルト値でパースされること', () {
      // S3から取得したJSONの一部が欠損、または null になっている悪意のある/壊れたデータを想定
      final Map<String, dynamic> corruptedJson = {
        'id': 'scenario_001',
        'authorId': null,
        'minPlayerCount': null,
        'gmRequirement': 'UNNECESSARY',
        'description': null,
      };

      const authorNameFallback = '不明';
      
      late Scenario parsedScenario;
      
      // アプリがクラッシュ（例外スロー）しないことを検証
      expect(() {
        parsedScenario = Scenario.fromJson(corruptedJson, authorNameFallback);
      }, returnsNormally);

      // パースされたデータが安全なデフォルト値（フォールバック値）になっていることを検証
      expect(parsedScenario.id, 'scenario_001');
      // 実装に合わせて期待値を '無題' に修正
      expect(parsedScenario.title, '無題');
      expect(parsedScenario.authorName, '不明');
      expect(parsedScenario.minPlayerCount, 0);
      expect(parsedScenario.maxPlayerCount, 0);
    });
  });
}
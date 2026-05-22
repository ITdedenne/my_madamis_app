import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

void main() {
  group('Scenario.fromJson のパーステスト', () {
    test('【正常系】すべてのデータが揃っている完全なJSONから正しくモデルが生成されること', () {
      final json = {
        'scenarioId': '101',
        'title': '完全なミステリー',
        'authorId': 'auth_999',
        'minPlayerCount': 4,
        'maxPlayerCount': 5,
        'gmRequirement': 'Required',
        'storeUrl': 'https://example.com/store',
      };

      final scenario = Scenario.fromJson(json, '作者A');

      expect(scenario.id, '101');
      expect(scenario.title, '完全なミステリー');
      expect(scenario.authorName, '作者A');
      expect(scenario.authorId, 'auth_999');
      expect(scenario.minPlayerCount, 4);
      expect(scenario.maxPlayerCount, 5);
      expect(scenario.gmRequirement, GmRequirement.required);
      expect(scenario.storeUrl, 'https://example.com/store');
      expect(scenario.titleLower, '完全なミステリー');
      expect(scenario.authorNameLower, '作者a'); // 小文字化チェック
    });

    test('【正常系 (Null安全)】一部のデータが欠落している(null)JSONでも、デフォルト値でクラッシュせずに生成されること', () {
      final json = {
        'title': null,
        'minPlayerCount': null,
        'gmRequirement': null,
      };

      final scenario = Scenario.fromJson(json, '不明な作者');

      // フォールバックされた値の検証
      expect(scenario.id, ''); // scenarioIdもidもないので空文字
      expect(scenario.title, '無題'); // デフォルト値の'無題'になること
      expect(scenario.authorName, '不明な作者');
      expect(scenario.minPlayerCount, 0); // nullなので0になること
      expect(scenario.maxPlayerCount, 0);
      expect(scenario.gmRequirement, GmRequirement.none); // 未知やnullは none になること
      expect(scenario.storeUrl, isNull);
    });

    test('【正常系 (型安全)】想定と異なる型(数値や大文字など)が混入したJSONでも正しく処理されること', () {
      final json = {
        'scenarioId': 12345, // Stringではなく数値で来た場合
        'title': 987, // 数値のタイトル
        'authorId': null,
        'minPlayerCount': 2.5, // 整数ではなく小数点付き
        'gmRequirement': 'OPTIONAL', // 大文字で来た場合
      };

      final scenario = Scenario.fromJson(json, 'TEST');

      expect(scenario.id, '12345'); // .toString() でStringに変換されること
      expect(scenario.title, '987');
      expect(scenario.authorId, '');
      expect(scenario.minPlayerCount, 2); // .toInt() により 2.5 -> 2 に切り捨てられること
      expect(scenario.gmRequirement, GmRequirement.optional); // .toLowerCase() でカバーされること
    });
  });
}
// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario_page.dart
// 内容: 【新規作成】

import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

class ScenarioPage {
  final List<Scenario> scenarios;
  final String? nextToken; // 次のページを取得するためのトークン

  ScenarioPage({
    required this.scenarios,
    this.nextToken,
  });

  // 次のページがあるかどうか
  bool get hasMore => nextToken != null;
}
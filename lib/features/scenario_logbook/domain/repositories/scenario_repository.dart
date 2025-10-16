// ファイルパス: lib/features/scenario_logbook/domain/repositories/scenario_repository.dart

import 'package:flutter/material.dart'; // RangeValuesのために必要
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

// データ層が実装すべき機能のインターフェース（契約）を定義
abstract class ScenarioRepository {
  /// 全てのシナリオをページネーションで取得する
  Future<List<Scenario>> fetchScenarios({
    required int page,
    int limit = 50,
    String? searchTerm,
    RangeValues? playerCountRange, // 絞り込み条件
    GmRequirement? gmRequirement,   // 絞り込み条件
  });

  /// ログインユーザーのマイリストを取得する
  Future<List<UserScenario>> fetchMyList();

  /// シナリオのステータスを更新・登録する
  Future<void> updateUserScenarioStatus(String scenarioId, UserScenarioStatus status);

  /// シナリオのステータスを削除する
  Future<void> removeUserScenarioStatus(String scenarioId);
}
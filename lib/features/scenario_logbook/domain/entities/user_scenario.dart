// ファイルパス: lib/features/scenario_logbook/domain/entities/user_scenario.dart

import 'package:equatable/equatable.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

// ユーザーのシナリオに対するステータス
enum UserScenarioStatus { played, possessed }

// ユーザーの記録（マイリストに表示するデータ）
class UserScenario extends Equatable {
  final Scenario scenario; // シナリオの詳細情報
  final UserScenarioStatus status; // 自分がどういう状態か

  const UserScenario({
    required this.scenario,
    required this.status,
  });

  @override
  List<Object?> get props => [scenario, status];
}
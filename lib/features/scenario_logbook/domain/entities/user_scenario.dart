// ファイルパス: lib/features/scenario_logbook/domain/entities/user_scenario.dart

import 'package:equatable/equatable.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

// 【変更点①】enumを廃止し、状態を管理するクラスに変更
class UserScenarioStatus extends Equatable {
  final bool isPlayed;
  final bool isPossessed;

  const UserScenarioStatus({
    this.isPlayed = false,
    this.isPossessed = false,
  });

  // どちらもfalseなら「未登録」とみなす
  bool get isUnregistered => !isPlayed && !isPossessed;

  @override
  List<Object?> get props => [isPlayed, isPossessed];
}


// UserScenarioクラスは変更なし（statusの型が新しいクラスになる）
class UserScenario extends Equatable {
  final Scenario scenario;
  final UserScenarioStatus status;

  const UserScenario({
    required this.scenario,
    required this.status,
  });

  @override
  List<Object?> get props => [scenario, status];
}
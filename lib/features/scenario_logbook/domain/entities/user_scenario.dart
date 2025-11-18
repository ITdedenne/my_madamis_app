// ファイルパス: lib/features/scenario_logbook/domain/entities/user_scenario.dart

import 'package:equatable/equatable.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

// 状態を管理するクラス
class UserScenarioStatus extends Equatable {
  final bool isPlayed;
  final bool isPossessed;
  final bool wantsToGm; // ★ 追加: GM検討中 (要件 3.3.3)

  const UserScenarioStatus({
    this.isPlayed = false,
    this.isPossessed = false,
    this.wantsToGm = false,
  });

  // 全てfalseなら「未登録」とみなす
  // 要件 4.6.1 補足: 「未通過」の定義は isPlayed: false AND isPossessed: false AND wantsToGm: false
  bool get isUnregistered => !isPlayed && !isPossessed && !wantsToGm;

  @override
  List<Object?> get props => [isPlayed, isPossessed, wantsToGm];
  
  // copyWithメソッドを追加（UIでの部分更新用）
  UserScenarioStatus copyWith({
    bool? isPlayed,
    bool? isPossessed,
    bool? wantsToGm,
  }) {
    return UserScenarioStatus(
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed,
      wantsToGm: wantsToGm ?? this.wantsToGm,
    );
  }
}

// UserScenarioクラス
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
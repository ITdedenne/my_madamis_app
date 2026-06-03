import 'package:equatable/equatable.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

// 状態を管理するクラス
class UserScenarioStatus extends Equatable {
  final bool isPlayed;
  final bool isPossessed;
  final bool wantsToGm;
  final bool wantsToPlay;

  const UserScenarioStatus({
    this.isPlayed = false,
    this.isPossessed = false,
    this.wantsToGm = false,
    this.wantsToPlay = false,
  });

  // 全てfalseなら「未登録」とみなす
  bool get isUnregistered => !isPlayed && !isPossessed && !wantsToGm && !wantsToPlay;

  @override
  List<Object?> get props => [isPlayed, isPossessed, wantsToGm, wantsToPlay];
  
  UserScenarioStatus copyWith({
    bool? isPlayed,
    bool? isPossessed,
    bool? wantsToGm,
    bool? wantsToPlay,
  }) {
    return UserScenarioStatus(
      isPlayed: isPlayed ?? this.isPlayed,
      isPossessed: isPossessed ?? this.isPossessed,
      wantsToGm: wantsToGm ?? this.wantsToGm,
      wantsToPlay: wantsToPlay ?? this.wantsToPlay,
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
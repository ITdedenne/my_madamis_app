// ファイルパス: lib/features/scenario_logbook/domain/entities/user_scenario.dart

import 'package:equatable/equatable.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';

// 状態を管理するクラスに変更
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
  
  // ▼▼▼ 追加: DBのString値への変換 ▼▼▼
  String toStringValue() {
    if (isPlayed && isPossessed) return 'BOTH';
    if (isPlayed) return 'PLAYED';
    if (isPossessed) return 'POSSESSED';
    return ''; // 未登録の場合は空文字を返し、Repository側でDBレコードを削除/作成しない判断に使う
  }

  // ▼▼▼ 追加: DBのString値からの復元 ▼▼▼
  factory UserScenarioStatus.fromString(String status) {
    final upperStatus = status.toUpperCase();
    return UserScenarioStatus(
      isPlayed: upperStatus == 'PLAYED' || upperStatus == 'BOTH',
      isPossessed: upperStatus == 'POSSESSED' || upperStatus == 'BOTH',
    );
  }
}

// UserScenarioクラスは変更なし
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
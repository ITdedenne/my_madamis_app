// ファイルパス: lib/features/group_search/domain/entities/group_search_result.dart

import 'package:equatable/equatable.dart';

class GroupSearchResult extends Equatable {
  final String scenarioId;
  final bool isFriendWantsToPlay; // 参加メンバーの誰かが「PL希望」しているか

  const GroupSearchResult({
    required this.scenarioId,
    this.isFriendWantsToPlay = false,
  });

  @override
  List<Object?> get props => [scenarioId, isFriendWantsToPlay];
  
  // JSONデコード用ファクトリ (Lambdaからのレスポンス用)
  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    return GroupSearchResult(
      scenarioId: json['scenarioId'] as String,
      isFriendWantsToPlay: json['isFriendWantsToPlay'] as bool? ?? false,
    );
  }
}
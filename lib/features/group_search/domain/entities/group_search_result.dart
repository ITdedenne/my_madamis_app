// ファイルパス: lib/features/group_search/domain/entities/group_search_result.dart

import 'package:equatable/equatable.dart';

/// APIレスポンス全体をラップするクラス
class GroupSearchResponse extends Equatable {
  final List<String> ngScenarioIds;
  final List<GroupScenarioMetadata> metadata;

  const GroupSearchResponse({
    required this.ngScenarioIds,
    required this.metadata,
  });

  @override
  List<Object?> get props => [ngScenarioIds, metadata];

  factory GroupSearchResponse.fromJson(Map<String, dynamic> json) {
    return GroupSearchResponse(
      ngScenarioIds: (json['ngScenarioIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      metadata: (json['metadata'] as List?)
              ?.map((e) => GroupScenarioMetadata.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// シナリオごとの付加情報
class GroupScenarioMetadata extends Equatable {
  final String scenarioId;
  final List<String> wantsToPlayUserIds;
  final List<String> externalHolderUserIds;

  const GroupScenarioMetadata({
    required this.scenarioId,
    this.wantsToPlayUserIds = const [],
    this.externalHolderUserIds = const [],
  });

  @override
  List<Object?> get props => [scenarioId, wantsToPlayUserIds, externalHolderUserIds];

  factory GroupScenarioMetadata.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) =>
        (json[key] as List?)?.map((e) => e.toString()).toList() ?? [];

    return GroupScenarioMetadata(
      scenarioId: json['scenarioId'] as String,
      wantsToPlayUserIds: parseList('wantsToPlayUserIds'),
      externalHolderUserIds: parseList('externalHolderUserIds'),
    );
  }
}
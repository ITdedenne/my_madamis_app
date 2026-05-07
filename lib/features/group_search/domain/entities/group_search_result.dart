// ファイルパス: lib/features/group_search/domain/entities/group_search_result.dart

import 'package:equatable/equatable.dart';

class GroupSearchResult extends Equatable {
  final String scenarioId;
  final List<String> ngUserIds;
  final List<String> wantsToPlayUserIds;
  final List<String> possessedUserIds;   // ★ 追加: 所持
  final List<String> wantsToGmUserIds;   // ★ 追加: 購入検討

  const GroupSearchResult({
    required this.scenarioId,
    this.ngUserIds = const [],
    this.wantsToPlayUserIds = const [],
    this.possessedUserIds = const [],
    this.wantsToGmUserIds = const [],
  });

  @override
  List<Object?> get props => [scenarioId, ngUserIds, wantsToPlayUserIds, possessedUserIds, wantsToGmUserIds];

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) =>
        (json[key] as List?)?.map((e) => e.toString()).toList() ?? [];

    return GroupSearchResult(
      scenarioId: json['scenarioId'] as String,
      ngUserIds: parseList('ngUserIds'),
      wantsToPlayUserIds: parseList('wantsToPlayUserIds'),
      possessedUserIds: parseList('possessedUserIds'), // ★ マッピング
      wantsToGmUserIds: parseList('wantsToGmUserIds'), // ★ マッピング
    );
  }
}
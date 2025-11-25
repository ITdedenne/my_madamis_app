import 'package:equatable/equatable.dart';

class GroupSearchResult extends Equatable {
  final String scenarioId;
  final List<String> ngUserIds;
  final List<String> wantsToPlayUserIds;
  final List<String> externalHolderUserIds;

  const GroupSearchResult({
    required this.scenarioId,
    this.ngUserIds = const [],
    this.wantsToPlayUserIds = const [],
    this.externalHolderUserIds = const [],
  });

  @override
  List<Object?> get props => [scenarioId, ngUserIds, wantsToPlayUserIds, externalHolderUserIds];

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    List<String> parseList(String key) =>
        (json[key] as List?)?.map((e) => e.toString()).toList() ?? [];

    return GroupSearchResult(
      scenarioId: json['scenarioId'] as String,
      ngUserIds: parseList('ngUserIds'),
      wantsToPlayUserIds: parseList('wantsToPlayUserIds'),
      externalHolderUserIds: parseList('externalHolderUserIds'),
    );
  }
}
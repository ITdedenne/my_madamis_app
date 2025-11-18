// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario.dart

import 'package:equatable/equatable.dart';
// ★ 修正: amplify_models のインポートを削除

// GMの要否を表すEnum
enum GmRequirement { required, optional, none }

class Scenario extends Equatable {
  final String id;
  final String title;
  final String authorName;
  final String authorId; 
  final int minPlayerCount;
  final int maxPlayerCount;
  final GmRequirement gmRequirement;
  final String? storeUrl; 

  const Scenario({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorId, 
    required this.minPlayerCount,
    required this.maxPlayerCount,
    required this.gmRequirement,
    this.storeUrl, 
  });

  @override
  List<Object?> get props => [
        id,
        title,
        authorName,
        authorId, 
        minPlayerCount,
        maxPlayerCount,
        gmRequirement,
        storeUrl, 
      ];

  // JSON (S3) からの変換用
  factory Scenario.fromJson(Map<String, dynamic> json, String authorName) {
    GmRequirement gmReq;
    switch (json['gmRequirement']?.toLowerCase()) {
      case 'required':
        gmReq = GmRequirement.required;
        break;
      case 'optional':
        gmReq = GmRequirement.optional;
        break;
      case 'none':
      default: 
        gmReq = GmRequirement.none;
        break;
    }

    return Scenario(
      id: json['scenarioId'],
      title: json['title'],
      authorName: authorName, 
      authorId: json['authorId'],
      minPlayerCount: (json['minPlayerCount'] as num?)?.toInt() ?? 0,
      maxPlayerCount: (json['maxPlayerCount'] as num?)?.toInt() ?? 0,
      gmRequirement: gmReq,
      storeUrl: json['storeUrl'],
    );
  }
  
  // ★ 修正: fromModel ファクトリを削除しました。
}

// 拡張メソッド (変更なし)
extension GmRequirementGraphQLExtension on GmRequirement {
  String? toGraphQLString() {
    switch (this) {
      case GmRequirement.required:
        return 'required';
      case GmRequirement.optional:
        return 'optional';
      case GmRequirement.none:
        return 'none';
    }
  }
}
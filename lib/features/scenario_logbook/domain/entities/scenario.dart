// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario.dart

import 'package:equatable/equatable.dart';

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
  
  // ★ 追加: 検索パフォーマンス最適化用のキャッシュフィールド
  final String titleLower;
  final String authorNameLower;

  const Scenario({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorId,
    required this.minPlayerCount,
    required this.maxPlayerCount,
    required this.gmRequirement,
    this.storeUrl,
    // ★ 追加
    required this.titleLower,
    required this.authorNameLower,
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
        // ★ 追加 (Equatableの比較対象に含める)
        titleLower,
        authorNameLower,
      ];

   factory Scenario.fromJson(Map<String, dynamic> json, String authorName) {
    GmRequirement gmReq;
    switch (json['gmRequirement']?.toString().toLowerCase()) {
      case 'required':
        gmReq = GmRequirement.required;
        break;
      case 'optional':
        gmReq = GmRequirement.optional;
        break;
      default:
        gmReq = GmRequirement.none;
        break;
    }

    // ★ ここがエラーの原因を防ぐ最重要ポイントです
    // json['キー'] が null だった場合に備えて、?? '' で「空文字」を代入するようにします。
    final id = (json['scenarioId'] ?? json['id'] ?? '') as String;
    final title = (json['title'] ?? '') as String;
    final authorId = (json['authorId'] ?? '') as String;

    return Scenario(
      id: id,
      title: title,
      authorName: authorName,
      authorId: authorId,
      minPlayerCount: (json['minPlayerCount'] as num?)?.toInt() ?? 0,
      maxPlayerCount: (json['maxPlayerCount'] as num?)?.toInt() ?? 0,
      gmRequirement: gmReq,
      storeUrl: json['storeUrl'] as String?,
      titleLower: title.toLowerCase(),
      authorNameLower: authorName.toLowerCase(),
    );
  }
}

extension GmRequirementGraphQLExtension on GmRequirement {
  String get graphQLValue {
    switch (this) {
      case GmRequirement.required:
        return 'REQUIRED';
      case GmRequirement.optional:
        return 'OPTIONAL';
      case GmRequirement.none:
        return 'NONE';
    }
  }
}
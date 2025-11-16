// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario.dart
import 'package:equatable/equatable.dart';
// ★ 修正: Amplifyモデルのインポートを (fetchMyList のため) 復活
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;

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

  // ★ 追加: S3 (JSON) からの変換用
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
      authorName: authorName, // 引数で受け取る
      authorId: json['authorId'],
      minPlayerCount: (json['minPlayerCount'] as num?)?.toInt() ?? 0,
      maxPlayerCount: (json['maxPlayerCount'] as num?)?.toInt() ?? 0,
      gmRequirement: gmReq,
      storeUrl: json['storeUrl'],
    );
  }

  // ★ 復活: DynamoDB (GraphQL Model) からの変換用 (fetchMyList で使用)
  factory Scenario.fromModel(amplify_models.Scenario scenarioModel, String authorName) {
    GmRequirement gmReq;
    switch (scenarioModel.gmRequirement?.toLowerCase()) {
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
      id: scenarioModel.id,
      title: scenarioModel.title,
      authorName: authorName, // 引数で受け取る
      authorId: scenarioModel.author?.id ?? '', // ★ model.author.id をマッピング
      minPlayerCount: scenarioModel.minPlayerCount ?? 0,
      maxPlayerCount: scenarioModel.maxPlayerCount ?? 0,
      gmRequirement: gmReq,
      storeUrl: scenarioModel.storeUrl,
    );
  }

}

// ★ 修正: GmRequirementをGraphQL用の文字列に変換する拡張 (内容は変更なし)
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
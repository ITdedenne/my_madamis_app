// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario.dart
// 内容: 【修正】

import 'package:equatable/equatable.dart';
// Amplifyモデルを参照するためにインポートエイリアスを使用
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

  // ★★★ 修正点: `fromModel` のシグネチャと実装を修正 ★★★
  factory Scenario.fromModel(
      amplify_models.Scenario scenarioModel, 
      String authorName,
      String title, // title を引数で受け取る
  ) {
    // GmRequirementのマッピング (AmplifyモデルのStringからEnumへ)
    GmRequirement gmReq;
    // ★ 修正: scenarioModel.gmRequirement は String? のため null チェック
    switch (scenarioModel.gmRequirement?.toLowerCase()) {
      case 'required':
        gmReq = GmRequirement.required;
        break;
      case 'optional':
        gmReq = GmRequirement.optional;
        break;
      case 'none':
      default: // 不明な値やnullの場合は 'none' にフォールバック
        gmReq = GmRequirement.none;
        break;
    }

    return Scenario(
      id: scenarioModel.id,
      title: title, // ★ 修正: 引数の title を使用
      authorName: authorName, // 引数で受け取る
      authorId: scenarioModel.author?.id ?? '', // AuthorモデルからIDを取得
      minPlayerCount: scenarioModel.minPlayerCount ?? 0, // nullの場合は0にフォールバック
      maxPlayerCount: scenarioModel.maxPlayerCount ?? 0, // nullの場合は0にフォールバック
      gmRequirement: gmReq,
      storeUrl: scenarioModel.storeUrl,
    );
  }
}

// ★ 追加: GmRequirementをGraphQLで使いやすい文字列に変換する拡張
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
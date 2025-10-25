// ファイルパス: lib/features/scenario_logbook/domain/entities/scenario.dart
import 'package:equatable/equatable.dart';
// Amplifyモデルを参照するためにインポートエイリアスを使用
import 'package:my_madamis_app/models/ModelProvider.dart' as amplify_models;

// GMの要否を表すEnum
enum GmRequirement { required, optional, none }

class Scenario extends Equatable {
  final String id;
  final String title;
  final String authorName;
  final String authorId; // ★ 追加: Authorテーブルとの連携用
  final int minPlayerCount;
  final int maxPlayerCount;
  final GmRequirement gmRequirement;
  final String? storeUrl; // ★ 追加: storeUrlも表示等で使う可能性を考慮

  const Scenario({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorId, // ★ 追加
    required this.minPlayerCount,
    required this.maxPlayerCount,
    required this.gmRequirement,
    this.storeUrl, // ★ 追加
  });

  @override
  List<Object?> get props => [
        id,
        title,
        authorName,
        authorId, // ★ 追加
        minPlayerCount,
        maxPlayerCount,
        gmRequirement,
        storeUrl, // ★ 追加
      ];

  // ★ 追加: Amplifyモデルからドメインエンティティへの変換メソッド
  factory Scenario.fromModel(
      amplify_models.Scenario scenarioModel, String authorName) {
    // GmRequirementのマッピング (AmplifyモデルのStringからEnumへ)
    GmRequirement gmReq;
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
      title: scenarioModel.title,
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
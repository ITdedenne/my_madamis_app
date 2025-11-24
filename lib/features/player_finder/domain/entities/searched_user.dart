import 'package:my_madamis_app/models/ModelProvider.dart';

/// プレイヤーファインダー検索結果用の拡張ユーザーエンティティ
/// Userモデルに加え、検索条件（PL希望など）の状態を保持する
class SearchedUser {
  final User user;
  final bool wantsToPlay;

  const SearchedUser({
    required this.user,
    this.wantsToPlay = false,
  });
}
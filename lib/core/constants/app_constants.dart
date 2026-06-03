// ファイルパス: lib/core/constants/app_constants.dart

class AppConstants {
  // インスタンス化を防ぐ
  const AppConstants._();

  /// ユーザー1人あたりがフォローできるフレンズの最大数
  static const int maxFriendsCount = 100;

  /// APIの1回あたりの取得件数 (ページネーション用)
  static const int defaultPageSize = 50;
}
// ファイルパス: test/helpers/test_helpers.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:my_madamis_app/main.dart' as app;

/// WidgetTesterを拡張して、便利なカスタム機能を追加します。
extension ScreenshotExtension on WidgetTester {
  /// `testWidgets` 内で、デバッグ用のスクリーンショットを簡単に撮影します。
  ///
  /// Flutter標準のゴールデンテスト機能を使って画面全体を画像として保存します。
  /// 画像を生成・更新するには、`flutter test --update-goldens` コマンドを使用してください。
  ///
  /// [name] には、生成される画像ファイルのフォルダ名と名前を指定します (例: 'login/error_case')。
  Future<void> takeScreenshot({required String name}) async {
    // アプリのルートウィジェットを見つけて、画面全体を対象にする
    final finder = find.byType(app.MyApp);

    // Flutter標準のゴールデンファイルマッチャーで比較・画像生成を行う
    await expectLater(
      finder,
      matchesGoldenFile('goldens/$name.png'),
    );
  }
}
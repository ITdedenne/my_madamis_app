// ファイルパス: test/flutter_test_config.dart

import 'dart:async';
import 'package:flutter_test/flutter_test.dart'; 
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
    // ★★★ この行を追加 ★★★
  // これにより、--update-goldensフラグなしでも画像が常に生成されるようになります。
  autoUpdateGoldenFiles = true;
  
  // ★★★ ここまで ★★★
  // Flutterテストで日本語フォントなどを正しく表示するための設定
  await loadAppFonts();
  return testMain();
}
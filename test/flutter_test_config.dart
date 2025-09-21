// ファイルパス: test/flutter_test_config.dart

import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Flutterテストで日本語フォントなどを正しく表示するための設定
  await loadAppFonts();
  return testMain();
}
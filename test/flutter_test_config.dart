// ファイルパス: test/flutter_test_config.dart

import 'dart:async';
import 'package:flutter_test/flutter_test.dart'; 
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // これにより、--update-goldensフラグなしでも画像が常に生成できる。
  //スクリーンショットを使ったデバッグ中は非常に有効だが
  //将来的に「UIが意図せず変わっていないかチェックする」という目的（リグレッションテスト）でゴールデンテストを使いたい場合は、
  //この設定を false に戻すかコメントアウトする必要があり。
  //falseにしない場合、UIの差異が検出されず、常に画像が上書きされてしまう為。
  autoUpdateGoldenFiles = true;

  // Flutterテストで日本語フォントなどを正しく表示するための設定
  await loadAppFonts();
  return testMain();
}
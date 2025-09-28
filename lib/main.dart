// ファイルパス: lib/main.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/amplifyconfiguration.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';

Future<void> main() async {
  // ターミナルに強制的にログを出力
  print('--- main() 開始 ---');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  print('--- _configureAmplify() 呼び出し前 ---');
  final isAmplifyConfigured = await _configureAmplify();
  print('--- _configureAmplify() 呼び出し後 ---');
  print('--- Amplify設定結果: $isAmplifyConfigured ---');

  if (isAmplifyConfigured) {
    print('--- runApp(MyApp) 実行 ---');
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } else {
    print('--- runApp(ErrorApp) 実行 ---');
    runApp(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Text(
              'Amplifyの初期化に失敗しました。\nターミナルのログを確認してください。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _configureAmplify() async {
  try {
    print('--- _configureAmplify() 処理開始 ---');
    
    if (Amplify.isConfigured) {
       print('Amplifyは既に設定済みです。');
       return true;
    }

    final auth = AmplifyAuthCognito();
    
    print('--- Amplify.addPlugin() 呼び出し前 ---');
    await Amplify.addPlugin(auth);
    print('--- Amplify.addPlugin() 呼び出し後 ---');
    
    print('--- Amplify.configure() 呼び出し前 ---');
    await Amplify.configure(amplifyconfig);
    print('--- Amplify.configure() 呼び出し後 ---');
    
    print('--- _configureAmplify() 正常に完了 ---');
    return true;
  } on AmplifyAlreadyConfiguredException {
    print('Amplify設定済み例外をキャッチ。');
    return true;
  } catch (e, st) {
    print('!!!!!! _configureAmplify() で致命的なエラーが発生 !!!!!!');
    print('エラー内容: $e');
    print('スタックトレース: $st');
    return false;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('--- MyApp build() 開始 ---');
    final authState = ref.watch(authStateNotifierProvider);
    print('--- 現在の認証状態: ${authState.status} ---');

    // ... (UI部分は変更なし) ...
    Widget home;
    switch (authState.status) {
      case AuthStatus.authenticated:
        home = const HomePage();
        break;
      case AuthStatus.unauthenticated:
        home = const LoginPage();
        break;
      case AuthStatus.initial:
      default:
        home = const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }

    return MaterialApp(
      title: 'Cognito Auth App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
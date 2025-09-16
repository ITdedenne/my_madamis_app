// ファイルパス: lib/main.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'amplifyconfiguration.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  // Flutterアプリの初期化
  WidgetsFlutterBinding.ensureInitialized();
  // Amplifyの設定
  await _configureAmplify();
  // アプリの実行
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    // Authプラグインを追加
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);

    // Amplifyを設定
    await Amplify.configure(amplifyconfig);
    safePrint('Amplify configured successfully');
  } on Exception catch (e) {
    safePrint('An error occurred configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognito Auth App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(), // 開始画面をログイン画面に設定
    );
  }
}
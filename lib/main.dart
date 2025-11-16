// ファイルパス: lib/main.dart

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart'; // ★ 1. Storageプラグインをインポート
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/amplifyconfiguration.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    // 認証プラグイン
    final auth = AmplifyAuthCognito();
    
    // APIプラグイン
    final api = AmplifyAPI(modelProvider: ModelProvider.instance); 

    // ★ 2. Storageプラグインを初期化
    final storage = AmplifyStorageS3();

    // ★ 3. すべてのプラグインをAmplifyに追加
    await Amplify.addPlugins([auth, api, storage]);

    // Amplifyを設定
    await Amplify.configure(amplifyconfig);

    safePrint('Amplify configured successfully');
  } on Exception catch (e) {
    safePrint('Amplifyの設定中にエラーが発生しました: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);

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
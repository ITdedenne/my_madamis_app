// ファイルパス: lib/main.dart

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// amplifyconfiguration.dartのimportは不要なので削除します
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/login_page.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';

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
  // ---【重要】ステップ1でAWSコンソールからコピーした3つの値を、以下の変数に貼り付けてください ---
  const userPoolId = 'ap-northeast-1_VlS5MtFSZ'; // 例: 'ap-northeast-1_XXXXXXXXX'
  const userPoolWebClientId = '7k5v89dhlt9k3tkpbvnshn2gj3'; // 例: '5v7e06s334lhie3467gnnn6tce'
  const region = 'ap-northeast-1'; // 例: 'ap-northeast-1'
  // --------------------------------------------------------------------------------

  // 認証に必要な最低限の情報だけで、手動で設定文字列を構築します
  const amplifyconfig = '''{
      "UserAgent": "aws-amplify-cli/2.0",
      "Version": "1.0",
      "auth": {
          "plugins": {
              "awsCognitoAuthPlugin": {
                  "UserAgent": "aws-amplify-cli/0.1.0",
                  "Version": "0.1.0",
                  "IdentityManager": {
                      "Default": {}
                  },
                  "CognitoUserPool": {
                      "Default": {
                          "PoolId": "$userPoolId",
                          "AppClientId": "$userPoolWebClientId",
                          "Region": "$region"
                      }
                  },
                  "Auth": {
                      "Default": {
                          "authenticationFlowType": "USER_SRP_AUTH"
                      }
                  }
              }
          }
      }
  }''';

  try {
    if (Amplify.isConfigured) {
      return;
    }
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);
    
    // 手動で作成した正しい設定を読み込ませます
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
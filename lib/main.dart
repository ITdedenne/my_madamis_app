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
    // Webで安定動作させるため、最もシンプルな初期化方法に戻します
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);
    
    await Amplify.configure(amplifyconfig);

    safePrint('Amplify configured successfully');
  } on Exception catch (e) {
    safePrint('An error occurred configuring Amplify: $e');
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
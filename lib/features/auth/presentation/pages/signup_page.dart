// ファイルパス: lib/features/auth/presentation/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; 

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // ★追加: 規約スクロール用

  bool _hasReadTerms = false; // ★追加: 規約を最後まで読んだか
  bool _agreedToTerms = false; // ★追加: 規約に同意したか

  @override
  void initState() {
    super.initState();
    // ★追加: スクロール位置を監視して、一番下まで行ったらチェックを有効にする
    _scrollController.addListener(() {
      // 完全に下まで行かなくても判定されるよう、少し(20px)のゆとりを持たせる
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 20) {
        if (!_hasReadTerms) {
          setState(() {
            _hasReadTerms = true;
          });
        }
      }
    });

    // テキストが短くてスクロールバーが出ない場合の対策
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent <= 0) {
        setState(() {
          _hasReadTerms = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToNextStep() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (Amplify.isConfigured) {
           await Amplify.Auth.signOut();
        }
      } catch (e) {
        safePrint('既存セッションのサインアウトに失敗しました: $e');
        // エラーが発生しても処理は続行（セッションがない可能性が高いため）
      }

      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProfilePage(email: _emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規登録 (1/2)'),
        elevation: 0,
      ),
      // ★修正: ログイン画面と同じレイアウト(最大幅500)に統一
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'まず、メールアドレスを登録してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'メールアドレス',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || !value.contains('@')) {
                        return '有効なメールアドレスを入力してください';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ★追加: 利用規約エリア
                  const Text(
                    '利用規約',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180, // 規約エリアの高さ
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          '''利用規約

第1条（適用）
本規約は、ユーザーと当社との間の本サービスの利用に関わる一切の関係に適用されるものとします。

第2条（利用登録）
登録希望者が当社の定める方法によって利用登録を申請し、当社がこれを承認することによって、利用登録が完了するものとします。

第3条（ユーザーIDおよびパスワードの管理）
ユーザーは、自己の責任において、本サービスのユーザーIDおよびパスワードを適切に管理するものとします。

第4条（禁止事項）
ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。
1. 法令または公序良俗に違反する行為
2. 犯罪行為に関連する行為
3. 当社のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
4. その他、当社が不適切と判断する行為

第5条（本サービスの提供の停止等）
当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。

※最後までスクロールすると同意チェックボックスが有効になります。''',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ★追加: 同意チェックボックス
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        // 読んでいない場合はチェックボックスを無効化（null）
                        onChanged: _hasReadTerms
                            ? (bool? value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          '利用規約を最後まで読み、同意します',
                          style: TextStyle(
                            color: _hasReadTerms ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // ★修正: 同意していない場合はボタンを無効化（null）
                  PrimaryButton(
                    onPressed: _agreedToTerms ? _goToNextStep : null,
                    text: '次へ',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
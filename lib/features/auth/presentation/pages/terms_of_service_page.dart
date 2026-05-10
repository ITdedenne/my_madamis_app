import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用規約')),
      body: SafeArea(
        child: Column(
          children: [
            // 規約テキストエリア
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'マイマダミス 利用規約',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '''
第1条（目的）
本規約は、利用者が「マイマダミス」（以下「本サービス」）を利用する際の条件を定めるものです。

第2条（ネタバレの禁止）
本サービスはミステリーゲームを扱う性質上、シナリオの核心に触れる情報（犯人、トリック等）を公開設定の箇所に記載することを固く禁じます。

第3条（免責事項）
1. 本サービスは個人開発のプロトタイプであり、予告なくデータの消去やサービスの停止を行う場合があります。
2. 本サービスの利用により生じた損害について、開発者は一切の責任を負いません。

第4条（著作権）
ユーザーが投稿した内容の著作権はユーザーに帰属しますが、サービス運営に必要な範囲で開発者が利用することを許諾するものとします。

第5条（禁止事項）
他者のアカウントの不正利用、公序良俗に反する行為、サーバーに過度な負荷をかける行為を禁止します。
                      ''',
                      style: TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            
            // 同意ボタンエリア（常に有効）
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    // アプリのメインカラーに合わせて調整してください
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    '規約に同意する',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
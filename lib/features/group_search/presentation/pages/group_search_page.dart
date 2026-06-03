// ファイルパス: lib/features/group_search/presentation/pages/group_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/group_search_condition_area.dart';
import 'package:my_madamis_app/features/group_search/presentation/widgets/group_search_results_area.dart';

const double _kMobileBreakpoint = 600.0;

class GroupSearchPage extends ConsumerWidget {
  const GroupSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < _kMobileBreakpoint;

    return Scaffold(
      // キーボード表示時に画面が崩れるのを防ぐため、スマホ版（BottomSheet）のみリサイズを有効化
      resizeToAvoidBottomInset: isMobile,
      appBar: AppBar(
        title: const Text('グループ検索'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _kMobileBreakpoint) {
            // ==========================================
            // PC・タブレット向け: 2ペインレイアウト (左に条件、右に結果)
            // ==========================================
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左サイドバー (固定幅360px)
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: const GroupSearchConditionArea(isBottomSheet: false),
                ),
                // 右メイン表示エリア (検索結果)
                const Expanded(
                  child: GroupSearchResultsArea(),
                ),
              ],
            );
          } else {
            // ==========================================
            // スマホ向け: 検索結果を画面いっぱいに表示
            // ==========================================
            return const Column(
              children: [
                Expanded(
                  child: GroupSearchResultsArea(),
                ),
              ],
            );
          }
        },
      ),
      // スマホ版のみ、フローティングアクションボタン（FAB）からボトムシートを開く
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // フルスクリーンに近い高さまで広げるのを許可
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: const GroupSearchConditionArea(isBottomSheet: true),
                  ),
                );
              },
              icon: const Icon(Icons.group_add),
              label: const Text('メンバー変更・条件設定'),
            )
          : null,
    );
  }
}
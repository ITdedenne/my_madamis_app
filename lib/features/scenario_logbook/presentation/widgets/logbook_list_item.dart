// lib/features/scenario_logbook/presentation/widgets/logbook_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';

// 実行するアクションを定義します
enum _UpdateAction {
  togglePlayed, // 「通過済」をトグル
  togglePossessed, // 「所持」をトグル
  setUnregistered // 「未登録」にセット
}

class LogbookListItem extends ConsumerWidget {
  const LogbookListItem({
    super.key,
    required this.scenarioId,
    required this.title,
    this.authorName,
    required this.isPlayed,
    required this.isPossessed,
    required this.sourcePage, // 'search' または 'myList'
  });

  final String scenarioId;
  final String title;
  final String? authorName;
  final bool isPlayed;
  final bool isPossessed;
  final String sourcePage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: authorName != null ? Text(authorName!) : null,
        // --- ▼ 修正 ▼ ---
        // trailing 全体を PopupMenuButton に置き換える
        trailing: PopupMenuButton<_UpdateAction>(
          onSelected: (_UpdateAction action) {
            // 新しい状態を計算
            bool newIsPlayed = isPlayed;
            bool newIsPossessed = isPossessed;

            switch (action) {
              case _UpdateAction.togglePlayed:
                newIsPlayed = !isPlayed;
                break;
              case _UpdateAction.togglePossessed:
                newIsPossessed = !isPossessed;
                break;
              case _UpdateAction.setUnregistered:
                newIsPlayed = false;
                newIsPossessed = false;
                break;
            }
            _updateStatus(ref, newIsPlayed, newIsPossessed);
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<_UpdateAction>>[
            // 「通過済」チェックボックス
            CheckedPopupMenuItem<_UpdateAction>(
              value: _UpdateAction.togglePlayed,
              checked: isPlayed,
              child: const Text('通過済'),
            ),
            // 「所持」チェックボックス
            CheckedPopupMenuItem<_UpdateAction>(
              value: _UpdateAction.togglePossessed,
              checked: isPossessed,
              child: const Text('所持'),
            ),
            const PopupMenuDivider(),
            // 「未登録」ボタン
            const PopupMenuItem<_UpdateAction>(
              value: _UpdateAction.setUnregistered,
              child: Text('未登録'),
            ),
          ],
          // ここに「プラスアイコンとプルダウンボタンが両方出る」原因がありました。
          // PopupMenuButton の child に、表示したいカスタムウィジェットを一つだけ渡します。
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _getBorderColor(isPlayed, isPossessed)),
              borderRadius: BorderRadius.circular(20),
              color: _getBackgroundColor(isPlayed, isPossessed),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIconData(isPlayed, isPossessed),
                    color: _getIconColor(isPlayed, isPossessed), size: 18),
                const SizedBox(width: 6),
                Text(_getStatusText(isPlayed, isPossessed),
                    style:
                        TextStyle(color: _getIconColor(isPlayed, isPossessed))),
                // この Icon(Icons.arrow_drop_down) がプルダウンのアイコンになります。
                // PopupMenuButton のデフォルトのアイコンは表示されなくなります。
                Icon(Icons.arrow_drop_down,
                    color: _getIconColor(isPlayed, isPossessed)),
              ],
            ),
          ),
        ),
        // --- ▲ 修正 ▲ ---
      ),
    );
  }

  // ステータス更新ロジック
  void _updateStatus(WidgetRef ref, bool newIsPlayed, bool newIsPossessed) {
    if (sourcePage == 'search') {
      ref
          .read(searchScenariosViewModelProvider.notifier) // .notifier を使用
          .updateScenarioStatus(
            scenarioId,
            newIsPlayed,
            newIsPossessed,
          );
    } else {
      ref
          .read(myListViewModelProvider.notifier) // .notifier を使用
          .updateScenarioStatus(
            scenarioId,
            newIsPlayed,
            newIsPossessed,
          );
    }
  }

  // --- 以下、UIヘルパーメソッド ---

  String _getStatusText(bool isPlayed, bool isPossessed) {
    if (isPlayed && isPossessed) return '通過/所持';
    if (isPlayed) return '通過済';
    if (isPossessed) return '所持';
    return '未登録';
  }

  IconData _getIconData(bool isPlayed, bool isPossessed) {
    if (isPlayed) return Icons.check_circle; // 「通過済」を優先
    if (isPossessed) return Icons.inventory;
    return Icons.add;
  }

  Color _getIconColor(bool isPlayed, bool isPossessed) {
    if (isPlayed) return Colors.green; // 「通過済」を優先
    if (isPossessed) return Colors.blue;
    return Colors.grey.shade700;
  }

  Color _getBorderColor(bool isPlayed, bool isPossessed) {
    if (isPlayed) return Colors.green.shade200; // 「通過済」を優先
    if (isPossessed) return Colors.blue.shade200;
    return Colors.grey.shade400;
  }

  Color _getBackgroundColor(bool isPlayed, bool isPossessed) {
    if (isPlayed) return Colors.green.shade50; // 「通過済」を優先
    if (isPossessed) return Colors.blue.shade50;
    return Colors.grey.shade100;
  }
}
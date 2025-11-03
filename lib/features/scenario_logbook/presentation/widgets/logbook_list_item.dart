import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';
// 2つのViewModelをインポート
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';

class LogbookListItem extends ConsumerWidget {
  // オブジェクトではなく、必要なフィールドを直接受け取る
  final String scenarioId;
  final String title;
  final String? authorName;
  final bool? isPlayed;
  final bool? isPossessed;
  // 呼び出し元のページを判別するための引数
  final String sourcePage; // 'myList' または 'search'

  const LogbookListItem({
    super.key,
    required this.scenarioId,
    required this.title,
    this.authorName,
    this.isPlayed,
    this.isPossessed,
    required this.sourcePage, // 呼び出し元ページを必須にする
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, // props を直接使用
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '作者: ${authorName ?? '不明'}', // props を直接使用
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // ステータスボタンのウィジェット呼び出し
            _buildStatusButton(
              context,
              ref,
              scenarioId,
              isPlayed,
              isPossessed,
            ),
          ],
        ),
      ),
    );
  }

  /// ステータスに応じてボタンを構築し、タップでボトムシートを表示する
  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    String scenarioId,
    bool? isPlayed,
    bool? isPossessed,
  ) {
    // 両方のViewModelを読み込む
    final searchViewModel = ref.read(searchScenariosViewModelProvider.notifier);
    final myListViewModel = ref.read(myListViewModelProvider.notifier);

    final bool played = isPlayed ?? false;
    final bool possessed = isPossessed ?? false;

    // ボタンの見た目決定ロジック (変更なし)
    IconData iconData;
    String text;
    Color backgroundColor;
    Color foregroundColor = Colors.white;

    if (played && possessed) {
      iconData = Icons.bookmark_added;
      text = '通過/所持';
      backgroundColor = Colors.purple;
    } else if (played) {
      iconData = Icons.check_circle;
      text = '通過済';
      backgroundColor = Colors.green;
    } else if (possessed) {
      iconData = Icons.book;
      text = '所持';
      backgroundColor = Colors.orange;
    } else {
      iconData = Icons.add_circle_outline;
      text = '未登録';
      backgroundColor = Colors.blue;
    }

    return ElevatedButton.icon(
      icon: Icon(iconData, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        // ボトムシート表示 (変更なし)
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (builderContext) {
            return _StatusSelectionSheet(
              initialIsPlayed: played,
              initialIsPossessed: possessed,
              onStatusChanged: (newIsPlayed, newIsPossessed) {
                // --- ▼ 修正点 ▼ ---
                // 呼び出し元のページ(sourcePage)に応じて、
                // 対応するViewModelの更新メソッドを呼ぶ
                if (sourcePage == 'myList') {
                  myListViewModel.updateScenarioStatus(
                    scenarioId,
                    newIsPlayed,
                    newIsPossessed,
                  );
                } else {
                  // 'search' ページからの呼び出し
                  searchViewModel.updateScenarioStatus(
                    scenarioId,
                    newIsPlayed,
                    newIsPossessed,
                  );
                }
                // --- ▲ 修正点 ▲ ---
              },
            );
          },
        );
      },
    );
  }
}

/// ステータス選択用のボトムシートウィジェット
/// (このウィジェットは前回の修正から変更ありません)
class _StatusSelectionSheet extends StatefulWidget {
  final bool initialIsPlayed;
  final bool initialIsPossessed;
  final Function(bool newIsPlayed, bool newIsPossessed) onStatusChanged;

  const _StatusSelectionSheet({
    required this.initialIsPlayed,
    required this.initialIsPossessed,
    required this.onStatusChanged,
  });

  @override
  State<_StatusSelectionSheet> createState() => _StatusSelectionSheetState();
}

class _StatusSelectionSheetState extends State<_StatusSelectionSheet> {
  late bool _isPlayed;
  late bool _isPossessed;

  @override
  void initState() {
    super.initState();
    _isPlayed = widget.initialIsPlayed;
    _isPossessed = widget.initialIsPossessed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('✅ 通過済'),
              value: _isPlayed,
              onChanged: (value) => setState(() => _isPlayed = value!),
            ),
            CheckboxListTile(
              title: const Text('📚 所持'),
              value: _isPossessed,
              onChanged: (value) => setState(() => _isPossessed = value!),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  widget.onStatusChanged(_isPlayed, _isPossessed);
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
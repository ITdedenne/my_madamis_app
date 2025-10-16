// ファイルパス: lib/features/scenario_logbook/presentation/widgets/scenario_list_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

// シナリオ一覧の各行のUI
class ScenarioListItem extends StatelessWidget {
  final Scenario scenario;
  final UserScenarioStatus? status;
  final Function(UserScenarioStatus? newStatus) onStatusChanged;

  const ScenarioListItem({
    super.key,
    required this.scenario,
    this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(scenario.title),
      subtitle: Text('${scenario.authorName} / ${scenario.minPlayerCount}-${scenario.maxPlayerCount}人'),
      trailing: _buildStatusButton(context),
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    if (status == null) {
      // 未登録状態
      return IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _showStatusMenu(context));
    } else if (status == UserScenarioStatus.played) {
      // 通過済み
      return IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _showStatusMenu(context));
    } else {
      // 所持
      return IconButton(icon: const Icon(Icons.book, color: Colors.blue), onPressed: () => _showStatusMenu(context));
    }
  }

  // ステータスを選択するボトムシートを表示
  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('✅ 通過済にする'),
            onTap: () {
              onStatusChanged(UserScenarioStatus.played);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('📚 所持済にする'),
            onTap: () {
              onStatusChanged(UserScenarioStatus.possessed);
              Navigator.pop(context);
            },
          ),
          if (status != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('手帳から削除する'),
              onTap: () {
                onStatusChanged(null); // nullを渡して削除
                Navigator.pop(context);
              },
            ),
          ]
        ],
      ),
    );
  }
}
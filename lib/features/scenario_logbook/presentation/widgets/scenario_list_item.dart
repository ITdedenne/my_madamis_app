// ファイルパス: lib/features/scenario_logbook/presentation/widgets/scenario_list_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

class ScenarioListItem extends StatelessWidget {
  final Scenario scenario;
  final UserScenarioStatus status; // null許容ではなく、デフォルト値を持つオブジェクトを受け取る
  final Function(UserScenarioStatus newStatus) onStatusChanged;

  const ScenarioListItem({
    super.key,
    required this.scenario,
    this.status = const UserScenarioStatus(), // デフォルトは isPlayed/isPossessed が false
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(scenario.title),
      subtitle: Text('${scenario.authorName} / ${scenario.minPlayerCount}-${scenario.maxPlayerCount}人'),
      trailing: _buildStatusIcons(context),
    );
  }

  // 【変更点①】ステータスアイコンの表示ロジック
  Widget _buildStatusIcons(BuildContext context) {
    return InkWell(
      onTap: () => _showStatusMenu(context),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.isPlayed) const Icon(Icons.check_circle, color: Colors.green, size: 28),
            if (status.isPlayed && status.isPossessed) const SizedBox(width: 4),
            if (status.isPossessed) const Icon(Icons.book, color: Colors.blue, size: 28),
            if (status.isUnregistered) const Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
          ],
        ),
      ),
    );
  }

  // 【変更点②】複数選択可能なボトムシート
  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _StatusSelectionSheet(
        initialStatus: status,
        onStatusChanged: onStatusChanged,
      ),
    );
  }
}

// ボトムシートの中身をStatefulWidgetとして分離
class _StatusSelectionSheet extends StatefulWidget {
  final UserScenarioStatus initialStatus;
  final Function(UserScenarioStatus newStatus) onStatusChanged;

  const _StatusSelectionSheet({required this.initialStatus, required this.onStatusChanged});

  @override
  State<_StatusSelectionSheet> createState() => _StatusSelectionSheetState();
}

class _StatusSelectionSheetState extends State<_StatusSelectionSheet> {
  late bool _isPlayed;
  late bool _isPossessed;

  @override
  void initState() {
    super.initState();
    _isPlayed = widget.initialStatus.isPlayed;
    _isPossessed = widget.initialStatus.isPossessed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              widget.onStatusChanged(UserScenarioStatus(isPlayed: _isPlayed, isPossessed: _isPossessed));
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        )
      ],
    );
  }
}
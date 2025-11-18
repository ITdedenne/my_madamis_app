// ファイルパス: lib/features/scenario_logbook/presentation/widgets/scenario_list_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

class ScenarioListItem extends StatelessWidget {
  final Scenario scenario;
  final UserScenarioStatus status;
  final Function(UserScenarioStatus newStatus) onStatusChanged;
  // 要件 4.4.3: 他ユーザーのリスト閲覧時は操作を無効化するためのフラグ
  final bool isReadOnly; 

  const ScenarioListItem({
    super.key,
    required this.scenario,
    this.status = const UserScenarioStatus(),
    required this.onStatusChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(scenario.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${scenario.authorName} / ${scenario.minPlayerCount}-${scenario.maxPlayerCount}人'),
      // ReadOnlyの場合はアイコンのみ表示し、操作（タップ）は無効化
      trailing: isReadOnly ? _buildStatusIcons(context, enableTap: false) : _buildStatusIcons(context, enableTap: true),
    );
  }

  Widget _buildStatusIcons(BuildContext context, {required bool enableTap}) {
    final icons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 通過済
        if (status.isPlayed) const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.check_circle, color: Colors.green, size: 24),
        ),
        // 所持
        if (status.isPossessed) const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.book, color: Colors.blue, size: 24),
        ),
        // GM検討中 (New!)
        if (status.wantsToGm) const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.manage_accounts, color: Colors.orange, size: 24),
        ),
        // 未登録 (アイコンボタンとしてのプレースホルダー)
        if (status.isUnregistered) const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.add_circle_outline, color: Colors.grey, size: 24),
        ),
      ],
    );

    if (!enableTap) return icons;

    // v2.0改 要件 4.3.1: アイコンをタップするとステータス変更UI（ボトムシート）が開く
    return InkWell(
      onTap: () => _showStatusMenu(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: icons,
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _StatusSelectionSheet(
        initialStatus: status,
        onStatusChanged: onStatusChanged,
        scenarioTitle: scenario.title,
      ),
    );
  }
}

class _StatusSelectionSheet extends StatefulWidget {
  final UserScenarioStatus initialStatus;
  final Function(UserScenarioStatus newStatus) onStatusChanged;
  final String scenarioTitle;

  const _StatusSelectionSheet({
    required this.initialStatus,
    required this.onStatusChanged,
    required this.scenarioTitle,
  });

  @override
  State<_StatusSelectionSheet> createState() => _StatusSelectionSheetState();
}

class _StatusSelectionSheetState extends State<_StatusSelectionSheet> {
  late bool _isPlayed;
  late bool _isPossessed;
  late bool _wantsToGm;

  @override
  void initState() {
    super.initState();
    _isPlayed = widget.initialStatus.isPlayed;
    _isPossessed = widget.initialStatus.isPossessed;
    _wantsToGm = widget.initialStatus.wantsToGm;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              widget.scenarioTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),
          CheckboxListTile(
            title: const Text('✅ 通過済'),
            subtitle: const Text('プレイ済みです'),
            value: _isPlayed,
            onChanged: (value) => setState(() => _isPlayed = value!),
          ),
          CheckboxListTile(
            title: const Text('📚 所持'),
            subtitle: const Text('シナリオを持っています'),
            value: _isPossessed,
            onChanged: (value) => setState(() => _isPossessed = value!),
          ),
          CheckboxListTile(
            title: const Text('👑 GM検討中'),
            subtitle: const Text('GMをやりたい/検討しています'),
            value: _wantsToGm,
            onChanged: (value) => setState(() => _wantsToGm = value!),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // 状態を更新して閉じる
                widget.onStatusChanged(UserScenarioStatus(
                  isPlayed: _isPlayed,
                  isPossessed: _isPossessed,
                  wantsToGm: _wantsToGm,
                ));
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          )
        ],
      ),
    );
  }
}
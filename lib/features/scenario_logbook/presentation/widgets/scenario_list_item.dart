// ファイルパス: lib/features/scenario_logbook/presentation/widgets/scenario_list_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

class ScenarioListItem extends StatelessWidget {
  final Scenario scenario;
  final UserScenarioStatus status;
  final Function(UserScenarioStatus newStatus) onStatusChanged;
  final bool isReadOnly;
  final VoidCallback? onTap;

  const ScenarioListItem({
    super.key,
    required this.scenario,
    this.status = const UserScenarioStatus(),
    required this.onStatusChanged,
    this.isReadOnly = false,
    this.onTap,
  });

  Color? _getStatusColor() {
    if (status.isPlayed) return Colors.green.shade400;
    if (status.isPossessed) return Colors.blue.shade400;
    if (status.wantsToGm) return Colors.orange.shade400;
    if (status.wantsToPlay) return Colors.pink.shade400;
    return null;
  }

  // --- 表示改善用ヘルパーメソッド ---
  // ★ 改善: 初見ユーザー向けに「PL（プレイヤー数）」であることを明示
  String _getPlayerCountText() {
    if (scenario.minPlayerCount == scenario.maxPlayerCount) {
      return 'PL ${scenario.minPlayerCount}人';
    }
    return 'PL ${scenario.minPlayerCount}〜${scenario.maxPlayerCount}人';
  }

  String _getGmRequirementText() {
    switch (scenario.gmRequirement) {
      case GmRequirement.required:
        return 'GM必須';
      case GmRequirement.optional:
        return 'GM任意';
      case GmRequirement.none:
        return 'GM不要';
    }
  }

  IconData _getGmRequirementIcon() {
    switch (scenario.gmRequirement) {
      case GmRequirement.required:
        return Icons.assignment_ind; // 必須感のあるアイコン
      case GmRequirement.optional:
        return Icons.assignment_ind_outlined;
      case GmRequirement.none:
        return Icons.person_off_outlined; // GMレス用
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      // ignore: deprecated_member_use
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap ?? (isReadOnly ? null : () => _showStatusMenu(context)),
        child: Container(
          decoration: BoxDecoration(
            border: statusColor != null 
                ? Border(left: BorderSide(color: statusColor, width: 6))
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. タイトルとアクション
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // メタ情報を1行に集約し、Overflow対策と視認性を両立
                        DefaultTextStyle(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ) ?? const TextStyle(),
                          child: Row(
                            children: [
                              // 人数 (PL表記にアップデート)
                              const Icon(Icons.people_outline, size: 14),
                              const SizedBox(width: 4),
                              Text(_getPlayerCountText()),
                              
                              const SizedBox(width: 12),
                              
                              // GM要否
                              Icon(_getGmRequirementIcon(), size: 14),
                              const SizedBox(width: 4),
                              Text(_getGmRequirementText()),
                              
                              const SizedBox(width: 12),
                              
                              // 作者名 (Expandedで囲み、狭い画面でのOverflowを防ぐ)
                              Expanded(
                                child: Text(
                                  'by ${scenario.authorName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isReadOnly)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Icon(
                        Icons.more_vert, 
                        size: 20, 
                        color: theme.colorScheme.onSurfaceVariant
                      ),
                    ),
                ],
              ),
              
              // 2. ステータス表示 (コンパクトなチップ)
              if (!status.isUnregistered) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (status.isPlayed)
                      _CompactStatusChip(label: '通過済', color: Colors.green.shade700, bgColor: Colors.green.shade50),
                    if (status.isPossessed)
                      _CompactStatusChip(label: '所持', color: Colors.blue.shade700, bgColor: Colors.blue.shade50),
                    if (status.wantsToGm)
                      _CompactStatusChip(label: '購入検討', color: Colors.orange.shade700, bgColor: Colors.orange.shade50),
                    if (status.wantsToPlay)
                      _CompactStatusChip(label: 'PL希望', color: Colors.pink.shade700, bgColor: Colors.pink.shade50),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StatusSelectionSheet(
        initialStatus: status,
        onStatusChanged: onStatusChanged,
        scenarioTitle: scenario.title,
      ),
    );
  }
}

class _CompactStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _CompactStatusChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ステータス変更シート
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
  late bool _wantsToPlay;

  @override
  void initState() {
    super.initState();
    _isPlayed = widget.initialStatus.isPlayed;
    _isPossessed = widget.initialStatus.isPossessed;
    _wantsToGm = widget.initialStatus.wantsToGm;
    _wantsToPlay = widget.initialStatus.wantsToPlay;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.scenarioTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('✅ 通過済'),
            subtitle: const Text('プレイ済みです'),
            value: _isPlayed,
            onChanged: (value) => setState(() => _isPlayed = value!),
            activeColor: Colors.green,
          ),
          CheckboxListTile(
            title: const Text('📚 所持'),
            subtitle: const Text('シナリオを持っています'),
            value: _isPossessed,
            onChanged: (value) => setState(() => _isPossessed = value!),
            activeColor: Colors.blue,
          ),
          CheckboxListTile(
            title: const Text('🛒 シナリオ購入検討'),
            subtitle: const Text('購入を迷っています / GM可能です'),
            value: _wantsToGm,
            onChanged: (value) => setState(() => _wantsToGm = value!),
            activeColor: Colors.orange,
          ),
          CheckboxListTile(
            title: const Text('❤️ PL希望'),
            subtitle: const Text('このシナリオで遊びたいです'),
            value: _wantsToPlay,
            onChanged: (value) => setState(() => _wantsToPlay = value!),
            activeColor: Colors.pink,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                widget.onStatusChanged(UserScenarioStatus(
                  isPlayed: _isPlayed,
                  isPossessed: _isPossessed,
                  wantsToGm: _wantsToGm,
                  wantsToPlay: _wantsToPlay,
                ));
                Navigator.pop(context);
              },
              child: const Text('保存', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
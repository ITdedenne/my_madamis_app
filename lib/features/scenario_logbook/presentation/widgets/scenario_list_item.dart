// ファイルパス: lib/features/scenario_logbook/presentation/widgets/scenario_list_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

// --- デザイン定数 ---
const double _kCardElevation = 2.0;
const double _kCardBorderRadius = 12.0;
const double _kCardPadding = 10.0;
const double _kTitleFontSize = 16.0;
const double _kStatusIconSize = 14.0;
const double _kStatusLabelSize = 10.0;
const double _kChipHorizontalPadding = 6.0;
const double _kChipVerticalPadding = 2.0;
const double _kChipBorderRadius = 4.0;
const double _kIconSpacing = 4.0;
const double _kDividerHeight = 8.0;
const double _kSubtitleSpacing = 4.0;
const double _kColorBarWidth = 6.0;

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

  /// ステータスに基づいて「優先表示カラー」を決定する (v2.15)
  /// 優先順位: 通過済(緑) > 所持(青) > 購入検討(橙) > PL希望(桃)
  Color? _getStatusColor(BuildContext context) {
    if (status.isPlayed) return Colors.green.shade400;
    if (status.isPossessed) return Colors.blue.shade400;
    if (status.wantsToGm) return Colors.orange.shade400;
    if (status.wantsToPlay) return Colors.pink.shade400;
    return null; 
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);

    return Card(
      elevation: _kCardElevation,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap ?? (isReadOnly ? null : () => _showStatusMenu(context)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (statusColor != null)
                Container(
                  width: _kColorBarWidth,
                  color: statusColor,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(_kCardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const Divider(height: _kDividerHeight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildStatusChips(context),
                            ),
                          ),
                          if (!isReadOnly)
                            const Icon(
                              Icons.edit_note,
                              size: 20,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scenario.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _kTitleFontSize,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: _kSubtitleSpacing),
        Text(
          '${scenario.authorName} / ${scenario.minPlayerCount}-${scenario.maxPlayerCount}人',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusChips(BuildContext context) {
    if (status.isUnregistered) {
      return const Text(
        '未登録',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    // 複数ステータスがある場合、すべて表示する
    return Row(
      children: [
        if (status.isPlayed)
          const _StatusChip(icon: Icons.check_circle, label: '通過済', color: Colors.green),
        if (status.isPossessed)
          const _StatusChip(icon: Icons.book, label: '所持', color: Colors.blue),
        if (status.wantsToGm)
          const _StatusChip(icon: Icons.add_shopping_cart, label: '購入検討', color: Colors.orange),
        if (status.wantsToPlay)
          const _StatusChip(icon: Icons.favorite, label: 'PL希望', color: Colors.pink),
      ],
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _kChipHorizontalPadding,
          vertical: _kChipVerticalPadding,
        ),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_kChipBorderRadius),
          // ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _kStatusIconSize, color: color),
            const SizedBox(width: _kIconSpacing),
            Text(
              label,
              style: TextStyle(
                fontSize: _kStatusLabelSize,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.scenarioTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Divider(),
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
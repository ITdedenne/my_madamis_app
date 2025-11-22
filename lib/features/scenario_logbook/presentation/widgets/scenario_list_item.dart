import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';

// --- デザイン定数 (Magic Numbersの排除) ---
const double _kCardElevation = 2.0;
const double _kCardBorderRadius = 12.0;
const double _kCardPadding = 12.0;
const double _kTitleFontSize = 16.0;
const double _kStatusIconSize = 14.0;
const double _kStatusLabelSize = 10.0;
const double _kChipHorizontalPadding = 6.0;
const double _kChipVerticalPadding = 2.0;
const double _kChipBorderRadius = 4.0;
const double _kIconSpacing = 4.0;
const double _kDividerHeight = 16.0;
const double _kSubtitleSpacing = 4.0;
const double _kColorBarWidth = 6.0; // 左端のカラーバーの太さ

class ScenarioListItem extends StatelessWidget {
  final Scenario scenario;
  final UserScenarioStatus status;
  final Function(UserScenarioStatus newStatus) onStatusChanged;
  final bool isReadOnly;

  const ScenarioListItem({
    super.key,
    required this.scenario,
    this.status = const UserScenarioStatus(),
    required this.onStatusChanged,
    this.isReadOnly = false,
  });

  /// ステータスに基づいて「優先表示カラー」を決定する
  /// 優先順位: 通過済(緑) > GM検討(橙) > 所持(青)
  Color? _getStatusColor(BuildContext context) {
    if (status.isPlayed) return Colors.green.shade400;
    if (status.wantsToGm) return Colors.orange.shade400;
    if (status.isPossessed) return Colors.blue.shade400;
    return null; // 未登録時は色なし
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);

    return Card(
      elevation: _kCardElevation,
      clipBehavior: Clip.antiAlias, // カラーバーやリップルエフェクトを角丸に収める
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardBorderRadius),
      ),
      child: InkWell(
        onTap: isReadOnly ? null : () => _showStatusMenu(context),
        // IntrinsicHeight: カラーバーの高さをコンテンツに合わせて自動伸縮させるために必須
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 左端のカラーバー (ステータスがある場合のみ表示)
              if (statusColor != null)
                Container(
                  width: _kColorBarWidth,
                  color: statusColor,
                ),

              // 2. メインコンテンツエリア
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(_kCardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトルと基本情報
                      _buildHeader(context),

                      const Divider(height: _kDividerHeight),

                      // ステータス表示エリア
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildStatusChips(context),
                            ),
                          ),
                          // 操作アイコン (ReadOnlyでない場合のみ)
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

    return Row(
      children: [
        if (status.isPlayed)
          const _StatusChip(
              icon: Icons.check_circle, label: '通過済', color: Colors.green),
        if (status.isPossessed)
          const _StatusChip(icon: Icons.book, label: '所持', color: Colors.blue),
        if (status.wantsToGm)
          const _StatusChip(
              icon: Icons.manage_accounts, label: 'GM検討', color: Colors.orange),
      ],
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 画面サイズに応じて高さを調整できるようにする
      builder: (_) => _StatusSelectionSheet(
        initialStatus: status,
        onStatusChanged: onStatusChanged,
        scenarioTitle: scenario.title,
      ),
    );
  }
}

// --- 内部ウィジェット: ステータスチップ ---
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip(
      {required this.icon, required this.label, required this.color});

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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_kChipBorderRadius),
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

// --- 内部ウィジェット: ステータス変更ボトムシート ---
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
      // キーボード等が出た時のためにbottomのpaddingを調整 (viewInsets)
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
            title: const Text('👑 GM検討中'),
            subtitle: const Text('GMをやりたい/検討しています'),
            value: _wantsToGm,
            onChanged: (value) => setState(() => _wantsToGm = value!),
            activeColor: Colors.orange,
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
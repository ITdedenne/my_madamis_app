// ファイルパス: lib/features/group_search/presentation/widgets/group_scenario_grid_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';

class GroupScenarioGridItem extends StatelessWidget {
  final GroupSearchDisplayItem item;

  const GroupScenarioGridItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final scenario = item.scenario;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー部分 (色付きバーなどがあればここで)
            Container(
              height: 6,
              color: item.hasWantsToPlay ? Colors.pinkAccent : Colors.grey.shade300,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      scenario.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 人数・作者
                    Text(
                      '${scenario.minPlayerCount}-${scenario.maxPlayerCount}人 / ${scenario.authorName}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // バッジエリア
                    if (item.hasWantsToPlay)
                      _CompactBadge(
                        icon: Icons.favorite,
                        label: '${item.wantsToPlayNames.length}',
                        color: Colors.pink,
                      ),
                    if (item.externalHolderNames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _CompactBadge(
                        icon: Icons.person_add,
                        label: '外部GM: ${item.externalHolderNames.length}',
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.scenario.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.hasWantsToPlay) ...[
              _DetailSection(
                title: '遊びたいメンバー',
                names: item.wantsToPlayNames,
                color: Colors.pink,
                icon: Icons.favorite,
              ),
              const SizedBox(height: 16),
            ],
            if (item.externalHolderNames.isNotEmpty) ...[
              _DetailSection(
                title: '外部GM候補 (選択外フレンド)',
                names: item.externalHolderNames,
                color: Colors.orange,
                icon: Icons.person_add,
              ),
              const SizedBox(height: 16),
            ],
            const Text('※ このシナリオは選択メンバー全員が未通過です。', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }
}

class _CompactBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<String> names;
  final Color color;
  final IconData icon;

  const _DetailSection({required this.title, required this.names, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: names.map((name) => Chip(
            label: Text(name, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            backgroundColor: color.withOpacity(0.05),
            side: BorderSide.none,
          )).toList(),
        ),
      ],
    );
  }
}
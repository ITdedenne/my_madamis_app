// ファイルパス: lib/features/group_search/presentation/widgets/group_scenario_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/group_search/presentation/viewmodels/group_search_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/domain/entities/user_scenario.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/notifiers/user_scenario_status_notifier.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/widgets/scenario_list_item.dart';

class GroupScenarioCard extends ConsumerWidget {
  final GroupSearchDisplayItem item;
  final bool isNearMiss;

  const GroupScenarioCard({super.key, required this.item, this.isNearMiss = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatuses = ref.watch(userScenarioStatusProvider);
    final status = userStatuses[item.scenario.id] ?? const UserScenarioStatus();
    final opacity = isNearMiss ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Stack(
        children: [
          ScenarioListItem(
            scenario: item.scenario,
            status: status,
            onTap: () => _showResponsiveDetail(context),
            onStatusChanged: (newStatus) {
              ref.read(userScenarioStatusProvider.notifier).updateStatus(item.scenario.id, newStatus);
            },
          ),
          
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.hasWantsToPlay)
                  _CompactBadge(icon: Icons.favorite, count: item.wantsToPlayNames.length, color: Colors.pink),
                
                // 所持 (Book)
                if (item.possessedNames.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _CompactBadge(icon: Icons.book, count: item.possessedNames.length, color: Colors.blue),
                ],

                // 購入検討 (Cart)
                if (item.wantsToGmNames.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _CompactBadge(icon: Icons.shopping_cart, count: item.wantsToGmNames.length, color: Colors.orange),
                ],
                
                if (isNearMiss) ...[
                  const SizedBox(width: 4),
                  _CompactBadge(icon: Icons.block, count: item.ngUserNames.length, color: Colors.grey),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // アダプティブな詳細表示 (スマホならスワイプで閉じるModalBottomSheet、PCならAlertDialog)
  void _showResponsiveDetail(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600.0;

    final detailContent = SingleChildScrollView(
      child: Padding(
        padding: isMobile ? const EdgeInsets.all(24.0) : EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Text(
                item.scenario.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            if (item.hasWantsToPlay)
              _DetailSection(
                title: '遊びたいメンバー',
                names: item.wantsToPlayNames,
                color: Colors.pink,
                icon: Icons.favorite,
              ),
            
            if (item.possessedNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailSection(
                title: '所持しているメンバー',
                names: item.possessedNames,
                color: Colors.blue,
                icon: Icons.book,
              ),
            ],

            if (item.wantsToGmNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailSection(
                title: '購入を検討しているメンバー',
                names: item.wantsToGmNames,
                color: Colors.orange,
                icon: Icons.shopping_cart,
              ),
            ],

            if (isNearMiss) ...[
              const SizedBox(height: 16),
              _DetailSection(
                title: '通過済みのメンバー',
                names: item.ngUserNames,
                color: Colors.grey,
                icon: Icons.block,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const Text('※ 詳細なステータスは「シナリオ手帳」で確認できます。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (isMobile) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => detailContent,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(item.scenario.title),
          content: detailContent,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
          ],
        ),
      );
    }
  }
}

class _CompactBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _CompactBadge({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: names.map((n) => Chip(
            label: Text(n, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            backgroundColor: color.withValues(alpha: 0.05),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
          )).toList(),
        ),
      ],
    );
  }
}
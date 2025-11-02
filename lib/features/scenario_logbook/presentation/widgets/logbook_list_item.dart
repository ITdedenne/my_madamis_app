// lib/features/scenario_logbook/presentation/widgets/logbook_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/my_list_viewmodel.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/viewmodels/search_scenarios_viewmodel.dart';

// シナリオのステータスを表すEnum
enum ScenarioStatus {
  unregistered,
  played,
  possessed,
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

  ScenarioStatus get status {
    if (isPlayed) return ScenarioStatus.played;
    if (isPossessed) return ScenarioStatus.possessed;
    return ScenarioStatus.unregistered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: authorName != null ? Text(authorName!) : null,
        trailing: PopupMenuButton<ScenarioStatus>(
          onSelected: (ScenarioStatus newStatus) {
            _updateStatus(ref, newStatus);
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<ScenarioStatus>>[
            _buildPopupMenuItem(
                '通過済', ScenarioStatus.played, status == ScenarioStatus.played),
            _buildPopupMenuItem('所持', ScenarioStatus.possessed,
                status == ScenarioStatus.possessed),
            const PopupMenuDivider(),
            _buildPopupMenuItem('未登録', ScenarioStatus.unregistered,
                status == ScenarioStatus.unregistered),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _getBorderColor(status)),
              borderRadius: BorderRadius.circular(20),
              color: _getBackgroundColor(status),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIconData(status), color: _getIconColor(status), size: 18),
                const SizedBox(width: 6),
                Text(_getStatusText(status),
                    style: TextStyle(color: _getIconColor(status))),
                Icon(Icons.arrow_drop_down, color: _getIconColor(status)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ステータス更新ロジック
  void _updateStatus(WidgetRef ref, ScenarioStatus newStatus) {
    final bool newIsPlayed = newStatus == ScenarioStatus.played;
    final bool newIsPossessed = newStatus == ScenarioStatus.possessed;

    // どのViewModelのメソッドを叩くかを sourcePage で分岐
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

  PopupMenuItem<ScenarioStatus> _buildPopupMenuItem(
      String text, ScenarioStatus value, bool isSelected) {
    return PopupMenuItem<ScenarioStatus>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          if (isSelected) const Icon(Icons.check, color: Colors.blue),
        ],
      ),
    );
  }

  String _getStatusText(ScenarioStatus status) {
    switch (status) {
      case ScenarioStatus.played:
        return '通過済';
      case ScenarioStatus.possessed:
        return '所持';
      case ScenarioStatus.unregistered:
        return '未登録';
    }
  }

  IconData _getIconData(ScenarioStatus status) {
    switch (status) {
      case ScenarioStatus.played:
        return Icons.check_circle;
      case ScenarioStatus.possessed:
        return Icons.inventory;
      case ScenarioStatus.unregistered:
        return Icons.add;
    }
  }

  Color _getIconColor(ScenarioStatus status) {
    switch (status) {
      case ScenarioStatus.played:
        return Colors.green;
      case ScenarioStatus.possessed:
        return Colors.blue;
      case ScenarioStatus.unregistered:
        return Colors.grey.shade700;
    }
  }

  Color _getBorderColor(ScenarioStatus status) {
    switch (status) {
      case ScenarioStatus.played:
        return Colors.green.shade200;
      case ScenarioStatus.possessed:
        return Colors.blue.shade200;
      case ScenarioStatus.unregistered:
        return Colors.grey.shade400;
    }
  }

  Color _getBackgroundColor(ScenarioStatus status) {
    switch (status) {
      case ScenarioStatus.played:
        return Colors.green.shade50;
      case ScenarioStatus.possessed:
        return Colors.blue.shade50;
      case ScenarioStatus.unregistered:
        return Colors.grey.shade100;
    }
  }
}
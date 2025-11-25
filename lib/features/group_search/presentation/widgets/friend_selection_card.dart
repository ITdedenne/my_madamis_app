// ファイルパス: lib/features/group_search/presentation/widgets/friend_selection_card.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class FriendSelectionCard extends StatelessWidget {
  final User user;
  final bool isSelected;
  final VoidCallback onTap;

  const FriendSelectionCard({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 選択時のボーダーカラーと背景色
    final borderColor = isSelected ? colorScheme.primary : Colors.transparent;
    final backgroundColor = isSelected ? colorScheme.primaryContainer.withOpacity(0.2) : colorScheme.surfaceContainer;

    return Card(
      elevation: isSelected ? 4 : 0, // 選択時は少し浮き上がる
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2.5), // 選択がわかる太めの枠線
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アバター + 選択チェックマーク
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 名前 (太字)
              Text(
                user.username,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Bio (控えめに表示、IDは非表示)
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.bio!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
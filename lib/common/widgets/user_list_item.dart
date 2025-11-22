// ファイルパス: lib/common/widgets/user_list_item.dart

import 'package:flutter/material.dart';
import 'package:my_madamis_app/models/ModelProvider.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final bool isFollowing;
  final bool isProcessing;
  final VoidCallback? onActionButtonPressed;
  final VoidCallback? onTap;
  final String actionButtonLabel;
  final Color? actionButtonColor;
  final Color? actionButtonTextColor;

  const UserListItem({
    super.key,
    required this.user,
    this.isFollowing = false,
    this.isProcessing = false,
    required this.onActionButtonPressed,
    this.onTap,
    required this.actionButtonLabel,
    this.actionButtonColor,
    this.actionButtonTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // アイコン
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // ユーザー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${user.publicUserId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Bio (あれば表示)
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.bio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // アクションボタン (フォロー/解除)
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: isFollowing 
                ? OutlinedButton(
                    onPressed: isProcessing ? null : onActionButtonPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: actionButtonTextColor ?? Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: actionButtonColor ?? Theme.of(context).colorScheme.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: isProcessing 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(actionButtonLabel),
                  )
                : FilledButton(
                    onPressed: isProcessing ? null : onActionButtonPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: actionButtonColor,
                      foregroundColor: actionButtonTextColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: isProcessing 
                      ? SizedBox(
                          width: 14, 
                          height: 14, 
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary, 
                            strokeWidth: 2
                          )
                        )
                      : Text(actionButtonLabel),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
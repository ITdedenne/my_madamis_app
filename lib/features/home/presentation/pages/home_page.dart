// ファイルパス: lib/features/home/presentation/pages/home_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart'; // ★ 追加
import 'package:my_madamis_app/features/settings/presentation/pages/settings_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friends_page.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_scenario_select_page.dart';
import 'package:my_madamis_app/features/group_search/presentation/pages/group_search_page.dart'; // ★ 修正: 新しいページへ

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    // ★ 追加: ProfileViewModelからも情報を取得（フォールバック用）
    final profileState = ref.watch(profileViewModelProvider);
    
    final theme = Theme.of(context);

    // ★ 修正: 表示名の解決ロジック (AuthState > ProfileState > Guest)
    final displayUsername = authState.username ?? profileState.profile?.username ?? 'Guest';

    ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
      if (next.flashMessage != null && next.status == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.flashMessage!)),
          );
          ref.read(authStateNotifierProvider.notifier).clearFlashMessage();
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 背景 (変更なし)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
                  theme.colorScheme.surface,
                  theme.colorScheme.secondaryContainer.withOpacity(0.2),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 100,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  )
                ]
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Home',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      Row(
                        children: [
                          _GlassActionButton(
                            icon: Icons.settings_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsPage()),
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // _GlassActionButton(
                          //   icon: Icons.logout_rounded,
                          //   onTap: () => ref.read(authStateNotifierProvider.notifier).signOut(),
                          // ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ウェルカムヘッダー
                  _buildGlassWelcomeHeader(context, displayUsername), // ★ 修正後の名前を渡す
                  
                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'メニュー',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth >= 600;
                      final crossAxisCount = isWideScreen ? (constraints.maxWidth / 380).floor() : 1;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: isWideScreen ? 1.5 : 1.8,
                        children: [
                          _MenuCard(
                            title: 'シナリオ手帳',
                            description: '通過・所持シナリオを記録',
                            icon: Icons.menu_book,
                            gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScenarioLogbookPage())),
                          ),
                          _MenuCard(
                            title: 'フレンズ',
                            description: 'フォローリストとユーザー検索',
                            icon: Icons.people_alt_rounded,
                            gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage())),
                          ),
                          _MenuCard(
                            title: 'プレイヤーを探す',
                            description: 'シナリオを指定して未通過者を検索',
                            icon: Icons.person_search_rounded,
                            gradientColors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerFinderScenarioSelectPage())),
                          ),
                          _MenuCard(
                            title: 'グループ検索',
                            description: 'メンバー全員が遊べるシナリオを一括検索',
                            icon: Icons.groups_rounded,
                            gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupSearchPage())), // ★ 修正: 統合ページへ
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassWelcomeHeader(BuildContext context, String username) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            highlightColor: theme.colorScheme.primary.withOpacity(0.1),
            splashColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$username さん',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'プロフィールを確認・編集する',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24, bottom: -24,
                  child: Transform.rotate(angle: -0.2, child: Icon(icon, size: 140, color: Colors.white.withOpacity(0.1))),
                ),
                Positioned(
                  top: -20, left: -20,
                  child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1))),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
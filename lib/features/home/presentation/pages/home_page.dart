// ファイルパス: lib/features/home/presentation/pages/home_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_madamis_app/features/auth/presentation/notifiers/auth_state_notifier.dart';
import 'package:my_madamis_app/features/profile/presentation/pages/profile_page.dart';
import 'package:my_madamis_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:my_madamis_app/features/settings/presentation/pages/settings_page.dart';
import 'package:my_madamis_app/features/scenario_logbook/presentation/pages/scenario_logbook_page.dart';
import 'package:my_madamis_app/features/friends/presentation/pages/friends_page.dart';
import 'package:my_madamis_app/features/player_finder/presentation/pages/player_finder_scenario_select_page.dart';
import 'package:my_madamis_app/features/group_search/presentation/pages/group_search_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final profileState = ref.watch(profileViewModelProvider);
    
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final displayUsername = authState.username ?? profileState.profile?.username ?? 'Guest';

    ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
      if (next.flashMessage != null && next.status == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.flashMessage!),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          ref.read(authStateNotifierProvider.notifier).clearFlashMessage();
        });
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // ベースは清潔感のあるSurface（白/ライトグレー）
      body: Stack(
        children: [
          // === 1. 背景：マダレコのブランドカラーを「淡い光（アンビエント）」として配置 ===
          // 左上の淡い光
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.05), // 極めて薄いブランドカラー
                boxShadow: [
                  BoxShadow(
                    blurRadius: 100, // 大きくぼかして空間に溶け込ませる
                    color: primaryColor.withValues(alpha: 0.1),
                  )
                ]
              ),
            ),
          ),
          // 右下の淡い光（画面全体に対角線上の透明感を生む）
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 120,
                    color: primaryColor.withValues(alpha: 0.08),
                  )
                ]
              ),
            ),
          ),

          // === 2. メインコンテンツ（実用性・視認性MAX） ===
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダーエリア
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // ログイン画面から引き継いだ「手記（マダレコ）」のアイコンをさりげなく配置
                          Icon(
                            Icons.auto_stories_rounded,
                            color: primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Home',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      _GlassActionButton(
                        icon: Icons.settings_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildGlassWelcomeHeader(context, displayUsername),
                  
                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'メニュー',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
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
                          // 各カードの色は実用（機能の識別）のために元の鮮やかな色をキープ
                          _MenuCard(
                            title: 'シナリオ手帳',
                            description: '遊んだシナリオや、これから遊びたいシナリオを記録・管理しましょう。',
                            icon: Icons.menu_book,
                            gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScenarioLogbookPage())),
                          ),
                          _MenuCard(
                            title: 'フレンズ',
                            description: '一緒に遊んだ仲間をフォローして、お互いのマイリストを共有しよう。',
                            icon: Icons.people_alt_rounded,
                            gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage())),
                          ),
                          _MenuCard(
                            title: 'プレイヤーを探す',
                            description: '特定のシナリオを「まだ遊んでいないフレンド」を探して卓を立てよう。',
                            icon: Icons.person_search_rounded,
                            gradientColors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerFinderScenarioSelectPage())),
                          ),
                          _MenuCard(
                            title: 'グループ検索',
                            description: 'メンバーを選択して「誰がGMできるか」「何が遊べるか」を一発検索！',
                            icon: Icons.groups_rounded,
                            gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupSearchPage())),
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
    final primaryColor = theme.colorScheme.primary;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            highlightColor: primaryColor.withValues(alpha: 0.05),
            splashColor: primaryColor.withValues(alpha: 0.1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                // 真っ白ではなく、ほんの少しだけブランドカラーを混ぜて透明感（ガラス感）を出す
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.15), // 枠線にブランドカラーを適用
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
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
                                color: primaryColor,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$username さん',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'プロフィールを確認・編集する',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
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
    final primaryColor = theme.colorScheme.primary;
    
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
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.15)), // ボタンの枠線にもブランドカラー
              ),
              child: Icon(icon, color: primaryColor, size: 24), // アイコンをブランドカラーに
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
          // 影の色を少し上品（透明度を下げてぼかしを強く）に調整
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.25), 
            blurRadius: 16, 
            offset: const Offset(0, 8)
          ),
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
                  child: Transform.rotate(angle: -0.2, child: Icon(icon, size: 140, color: Colors.white.withValues(alpha: 0.1))),
                ),
                Positioned(
                  top: -20, left: -20,
                  child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1))),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.2), maxLines: 3, overflow: TextOverflow.ellipsis),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:ui'; // BackdropFilter用

import 'package:my_madamis_app/common/widgets/custom_text_form_field.dart';
import 'package:my_madamis_app/common/widgets/primary_button.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:my_madamis_app/features/auth/presentation/pages/signup_page.dart';
import 'package:my_madamis_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:my_madamis_app/features/home/presentation/pages/home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(loginViewModelProvider);
    final primaryColor = Theme.of(context).primaryColor;

    ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }

      if (next.isAuthenticated) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white), // 戻るボタンなどを白に
      ),
      body: Stack(
        children: [
          // === 1. 最背面：夜空の深みを表現するグラデーション ===
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1021), // 深いミッドナイトブルー
                    Color(0xFF1B2735), // 少し明るい夜空
                    Color(0xFF090A0F), // 地平線に近い漆黒
                  ],
                ),
              ),
            ),
          ),

          // === 2. 中間面：本物の夜空のような「瞬く星々」 ===
          const Positioned.fill(
            child: IgnorePointer(
              child: NightSkyBackground(),
            ),
          ),
          
          // === 3. 前面：すりガラス風（グラスモーフィズム）のログインフォーム ===
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  // この画面のフォームだけをダークモード化する高度なテクニック
                  child: Theme(
                    data: ThemeData.dark().copyWith(
                      primaryColor: primaryColor,
                      colorScheme: ColorScheme.dark(primary: primaryColor),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0), // すりガラス効果
                        child: Container(
                          padding: const EdgeInsets.all(40.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: _buildForm(context, viewModel, primaryColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, LoginState viewModel, Color primaryColor) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.auto_stories_rounded,
              size: 56,
              color: primaryColor.withValues(alpha: 0.9), // 夜空に合わせて少し透けさせる
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'マダレコ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          CustomTextFormField(
            controller: _emailController,
            labelText: 'メールアドレス',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? 'メールアドレスを入力してください' : null,
          ),
          
          const SizedBox(height: 24),
          
          CustomTextFormField(
            controller: _passwordController,
            labelText: 'パスワード',
            obscureText: _isObscure, 
            suffixIcon: IconButton( 
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'パスワードを入力してください' : null,
          ),
          
          const SizedBox(height: 8),
          
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
              ),
              child: const Text(
                'パスワードを忘れた場合',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          PrimaryButton(
            text: 'ログイン',
            isLoading: viewModel.isLoading,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ref.read(loginViewModelProvider.notifier).signIn(
                  _emailController.text,
                  _passwordController.text,
                );
              }
            },
          ),
          
          const SizedBox(height: 48), 
          
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'はじめての方',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
            ],
          ),
          
          const SizedBox(height: 24),
          
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpPage()),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              '新規アカウント作成',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryColor, // ボタンの文字色をプライマリに
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 没入感を高める「本物の夜空」アニメーションウィジェット
// ============================================================================

class NightSkyBackground extends StatefulWidget {
  const NightSkyBackground({super.key});

  @override
  State<NightSkyBackground> createState() => _NightSkyBackgroundState();
}

class _NightSkyBackgroundState extends State<NightSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_StarNode> _stars;
  
  // 星の数を大幅に増やし、密度を上げることでリアリティを出します
  final int _starCount = 180; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..forward();

    final random = Random();
    _stars = List.generate(_starCount, (index) {
      // 大半は小さな星、ごく一部を大きな星にしてメリハリをつける
      final isLargeStar = random.nextDouble() > 0.92;
      
      return _StarNode(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: isLargeStar ? 1.5 + random.nextDouble() * 2.0 : 0.5 + random.nextDouble() * 1.2,
        blinkSpeed: 0.5 + random.nextDouble() * 2.5,
        blinkOffset: random.nextDouble() * pi * 2,
        // 星空全体がごく僅かに横へ流れる（地球の自転を表現）
        driftX: 0.002 + random.nextDouble() * 0.003,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0.0;
        return CustomPaint(
          size: Size.infinite,
          painter: _NightSkyPainter(
            stars: _stars,
            time: t / 1000.0,
          ),
        );
      },
    );
  }
}

class _StarNode {
  final double x;
  final double y;
  final double size;
  final double blinkSpeed;
  final double blinkOffset;
  final double driftX;

  _StarNode({
    required this.x,
    required this.y,
    required this.size,
    required this.blinkSpeed,
    required this.blinkOffset,
    required this.driftX,
  });
}

class _NightSkyPainter extends CustomPainter {
  final List<_StarNode> stars;
  final double time;

  _NightSkyPainter({
    required this.stars,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // 画面をゆっくりループして横切る計算
      double xPos = (star.x + star.driftX * time) % 1.0;
      if (xPos < 0) xPos += 1.0;
      
      final currentX = xPos * size.width;
      final currentY = star.y * size.height;

      // 星の瞬き（サイン波を使用して自然な明滅を表現）
      final double blink = sin(time * star.blinkSpeed + star.blinkOffset);
      
      // 不透明度のベース値を下げ、よりリアルな遠くの星を表現
      const double baseOpacity = 0.1;
      const double maxOpacity = 0.8;
      final double opacity = (baseOpacity + (blink + 1.0) / 2.0 * (maxOpacity - baseOpacity)).clamp(0.0, 1.0);

      // 星自体は純白（Colors.white）にし、サイズや透明度で遠近感を出す
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
        
      // 大きめの星には発光エフェクト（ブラー）をつける
      if (star.size > 2.0) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      }

      canvas.drawCircle(Offset(currentX, currentY), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NightSkyPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
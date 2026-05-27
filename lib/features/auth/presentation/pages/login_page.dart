// ファイルパス: lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:ui';

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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // === 1. 背景：夜空の深みを表現するグラデーション ===
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1021),
                    Color(0xFF1B2735),
                    Color(0xFF090A0F),
                  ],
                ),
              ),
            ),
          ),

          // === 2. 背景アニメーション：瞬く星々と星座 ===
          const Positioned.fill(
            child: IgnorePointer(
              child: NightSkyBackground(showLines: true),
            ),
          ),
          
          // === 3. 中央配置のグラスモーフィズムフォーム ===
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
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
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
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
              color: primaryColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'マダレコ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '一生に一度の体験を刻む。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
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
              child: const Text('パスワードを忘れた場合', style: TextStyle(color: Colors.white70)),
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
          
          const SizedBox(height: 40), 
          
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            child: Text(
              '新規アカウント作成',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

// === 共通星空ペインタークラス ===
class NightSkyBackground extends StatefulWidget {
  final bool showLines;
  const NightSkyBackground({super.key, this.showLines = false});

  @override
  State<NightSkyBackground> createState() => _NightSkyBackgroundState();
}

class _NightSkyBackgroundState extends State<NightSkyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  final int _starCount = 120;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(days: 365))..forward();
    final random = Random();
    _stars = List.generate(_starCount, (index) {
      return _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() > 0.85 ? 1.5 + random.nextDouble() * 1.5 : 0.4 + random.nextDouble() * 1.0,
        blinkSpeed: 0.6 + random.nextDouble() * 2.0,
        blinkOffset: random.nextDouble() * pi * 2,
        driftX: 0.001 + random.nextDouble() * 0.002,
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
          painter: _NightSkyPainter(stars: _stars, time: t / 1000.0, showLines: widget.showLines, color: Theme.of(context).primaryColor),
        );
      },
    );
  }
}

class _Star {
  final double x; final double y; final double size; final double blinkSpeed; final double blinkOffset; final double driftX;
  _Star({required this.x, required this.y, required this.size, required this.blinkSpeed, required this.blinkOffset, required this.driftX});
}

class _NightSkyPainter extends CustomPainter {
  final List<_Star> stars; final double time; final bool showLines; final Color color;
  _NightSkyPainter({required this.stars, required this.time, required this.showLines, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> positions = [];
    final List<double> opacities = [];

    for (var star in stars) {
      double xPos = (star.x + star.driftX * time) % 1.0;
      if (xPos < 0) xPos += 1.0;
      positions.add(Offset(xPos * size.width, star.y * size.height));
      final double blink = sin(time * star.blinkSpeed + star.blinkOffset);
      opacities.add((0.1 + (blink + 1.0) / 2.0 * 0.6).clamp(0.0, 1.0));
    }

    if (showLines) {
      final double maxConnectDistance = min(size.width, size.height) * 0.20;
      for (int i = 0; i < positions.length; i++) {
        for (int j = i + 1; j < positions.length; j++) {
          final double distance = (positions[i] - positions[j]).distance;
          if (distance < maxConnectDistance) {
            final double lineOpacity = (1.0 - (distance / maxConnectDistance)) * (opacities[i] + opacities[j]) * 0.12;
            canvas.drawLine(positions[i], positions[j], Paint()..color = color.withValues(alpha: lineOpacity.clamp(0.0, 0.08))..strokeWidth = 0.6);
          }
        }
      }
    }

    for (int i = 0; i < positions.length; i++) {
      final paint = Paint()..color = Colors.white.withValues(alpha: opacities[i]);
      if (stars[i].size > 1.8) paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(positions[i], stars[i].size, paint);
    }
  }
  @override bool shouldRepaint(covariant _NightSkyPainter oldDelegate) => oldDelegate.time != time;
}
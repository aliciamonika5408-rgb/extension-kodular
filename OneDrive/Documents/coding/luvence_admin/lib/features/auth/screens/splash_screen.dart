import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../services/auth_service.dart';
import '../../../navigation/app_navigation.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _shimmerController;
  late AnimationController _ringController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotate;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _ringExpand;
  late Animation<double> _ringFade;

  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _initParticles();

    // Logo animation - elastic bounce
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );
    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.6, curve: Curves.easeOutCubic)),
    );

    // Text animation
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Shimmer effect on text
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Ring pulse
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _ringExpand = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ringFade = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    // Particle float
    _particleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();

    _startAnimations();
  }

  void _initParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.3 + 0.1,
        delay: _random.nextDouble() * 2,
        opacity: _random.nextDouble() * 0.3 + 0.05,
      ));
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    _checkAuth();
  }

  void _checkAuth() async {
    if (!mounted) return;

    // If already logged in, check admin
    if (AuthService.isLoggedIn) {
      final isAdmin = await AuthService.isAdmin();
      _navigateTo(isAdmin ? const AppNavigation() : const LoginScreen());
      return;
    }

    // Listen for incoming deep link session (OAuth callback)
    // Wait a short time for Supabase to process the deep link
    await Future.delayed(const Duration(milliseconds: 500));

    if (AuthService.isLoggedIn) {
      final isAdmin = await AuthService.isAdmin();
      _navigateTo(isAdmin ? const AppNavigation() : const LoginScreen());
      return;
    }

    // No session, go to login
    _navigateTo(const LoginScreen());
  }

  void _navigateTo(Widget destination) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: LuvColors.background,
      body: Stack(
        children: [
          // Animated floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleController.value,
                color: LuvColors.accent,
              ),
            ),
          ),

          // Ambient gradient orbs
          _buildAmbientOrb(size, 0.2, 0.15, 200, LuvColors.accent.withValues(alpha: 0.04)),
          _buildAmbientOrb(size, 0.8, 0.75, 180, const Color(0xFF8B5CF6).withValues(alpha: 0.03)),
          _buildAmbientOrb(size, 0.5, 0.3, 250, LuvColors.accent.withValues(alpha: 0.06)),

          // Pulsing ring behind logo
          Center(
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) => Opacity(
                opacity: _ringFade.value,
                child: Transform.scale(
                  scale: _ringExpand.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LuvColors.accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Second ring (delayed)
          Center(
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) {
                final delayed = (_ringController.value + 0.5) % 1.0;
                final scale = 0.8 + (delayed * 0.8);
                final opacity = (1 - delayed) * 0.25;
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: LuvColors.accent.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with rotation + scale
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: LuvColors.accent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LuvColors.accent.withValues(alpha: 0.25),
                                blurRadius: 40,
                                spreadRadius: -5,
                              ),
                              BoxShadow(
                                color: LuvColors.accent.withValues(alpha: 0.1),
                                blurRadius: 80,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: LuvColors.surface,
                                child: Center(
                                  child: Text('L',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w700,
                                      color: LuvColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Brand name with shimmer
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        // Shimmer gold text
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (_, child) => ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment(_shimmerAnimation.value - 1, 0),
                              end: Alignment(_shimmerAnimation.value, 0),
                              colors: const [
                                LuvColors.accent,
                                LuvColors.accentLight,
                                Color(0xFFFFF8E7),
                                LuvColors.accentLight,
                                LuvColors.accent,
                              ],
                              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            ).createShader(bounds),
                            child: child,
                          ),
                          child: Text(
                            'LUVENCE',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Divider line
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Container(
                            width: 60 * v,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  LuvColors.accent.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtitle with typewriter effect
                        _TypewriterText(
                          text: 'ADMIN DASHBOARD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LuvColors.textMuted,
                            letterSpacing: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 70),

                // Loading indicator
                FadeTransition(
                  opacity: _textFade,
                  child: _buildLoadingIndicator(),
                ),
              ],
            ),
          ),

          // Bottom branding
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  Text(
                    '✦ Luxury Perfume Management ✦',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: LuvColors.accent.withValues(alpha: 0.3),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: LuvColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientOrb(Size size, double xFrac, double yFrac, double diameter, Color color) {
    return Positioned(
      left: size.width * xFrac - diameter / 2,
      top: size.height * yFrac - diameter / 2,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (_, __) {
          final offset = sin(_particleController.value * 2 * pi) * 10;
          return Transform.translate(
            offset: Offset(offset, offset * 0.5),
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color, Colors.transparent]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          // Outer ring
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: LuvColors.accent.withValues(alpha: 0.15),
            ),
          ),
          // Inner dot spinning
          AnimatedBuilder(
            animation: _ringController,
            builder: (_, __) {
              final angle = _ringController.value * 2 * pi;
              return Transform.rotate(
                angle: angle,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuvColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: LuvColors.accent.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Typewriter text effect
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _animate();
  }

  void _animate() async {
    await Future.delayed(const Duration(milliseconds: 300));
    while (_index < widget.text.length && mounted) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) {
        setState(() {
          _index++;
          _displayed = widget.text.substring(0, _index);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}

// Floating particles
class _Particle {
  double x, y, size, speed, delay, opacity;
  _Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.delay, required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final adjustedProgress = (progress + p.delay) % 1.0;
      final y = (p.y - adjustedProgress * p.speed) % 1.0;
      final fadeIn = (adjustedProgress * 3).clamp(0.0, 1.0);
      final fadeOut = ((1 - adjustedProgress) * 3).clamp(0.0, 1.0);
      final alpha = p.opacity * fadeIn * fadeOut;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.5);

      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/gold_button.dart';
import '../services/auth_service.dart';
import '../../../navigation/app_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Email dan password harus diisi');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await AuthService.signIn(_emailController.text.trim(), _passwordController.text);
      final isAdmin = await AuthService.isAdmin();

      if (!isAdmin) {
        await AuthService.signOut();
        if (mounted) setState(() { _error = 'Akun Anda tidak memiliki akses admin'; _isLoading = false; });
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppNavigation(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Invalid login') ? 'Email atau password salah' : 'Terjadi kesalahan: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _isGoogleLoading = true; _error = null; });

    try {
      final launched = await AuthService.signInWithGoogle();
      if (!launched) {
        if (mounted) setState(() { _error = 'Gagal membuka halaman login Google'; _isGoogleLoading = false; });
        return;
      }

      // Listen for auth state change (deep link callback)
      final session = await AuthService.waitForOAuthSession();

      if (session == null) {
        if (mounted) setState(() { _error = 'Login Google dibatalkan atau timeout'; _isGoogleLoading = false; });
        return;
      }

      // Small delay to ensure session is fully established
      await Future.delayed(const Duration(milliseconds: 300));

      // Check admin role
      final isAdmin = await AuthService.isAdmin();
      if (!isAdmin) {
        await AuthService.signOut();
        if (mounted) setState(() { _error = 'Akun Google Anda tidak memiliki akses admin'; _isGoogleLoading = false; });
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppNavigation(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Login Google gagal: ${e.toString()}';
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background gradient orbs
            Positioned(top: -100, right: -50,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [LuvColors.accent.withValues(alpha: 0.06), Colors.transparent]),
              )),
            ),
            Positioned(bottom: -80, left: -60,
              child: Container(width: 250, height: 250, decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.04), Colors.transparent]),
              )),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: LuvColors.accent.withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: LuvColors.accent.withValues(alpha: 0.15), blurRadius: 24)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('LUVENCE', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: LuvColors.textPrimary, letterSpacing: 6)),
                      const SizedBox(height: 4),
                      Text('ADMIN DASHBOARD', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, letterSpacing: 3, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 40),

                      // Glass login card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                begin: Alignment(-0.8, -1), end: Alignment(0.8, 1),
                                colors: [Color(0x801E2332), Color(0x990A0C14)],
                              ),
                              border: Border.all(color: LuvColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome Back', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: LuvColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('Masuk ke admin dashboard', style: TextStyle(fontSize: 12, color: LuvColors.textTertiary)),
                                const SizedBox(height: 28),

                                // Email
                                Text('EMAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.accent.withValues(alpha: 0.5))),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'admin@luvence.id',
                                    prefixIcon: Icon(Icons.email_outlined, size: 18, color: LuvColors.textMuted),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Password
                                Text('PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.accent.withValues(alpha: 0.5))),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  onSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: LuvColors.textMuted),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: LuvColors.textMuted),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Error
                                if (_error != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: LuvColors.errorBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: LuvColors.error.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, size: 16, color: LuvColors.error),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: LuvColors.error))),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 28),

                                // Login Button
                                GoldButton(
                                  label: 'Masuk ke Dashboard',
                                  onPressed: _isLoading ? null : _login,
                                  isLoading: _isLoading,
                                  expanded: true,
                                  icon: Icons.arrow_forward_rounded,
                                ),

                                const SizedBox(height: 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Container(height: 0.5, color: LuvColors.border)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text('atau', style: TextStyle(fontSize: 11, color: LuvColors.textMuted, fontWeight: FontWeight.w500)),
                                    ),
                                    Expanded(child: Container(height: 0.5, color: LuvColors.border)),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Google Sign-In
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                                    ),
                                    child: _isGoogleLoading
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: LuvColors.textMuted),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 20, height: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Center(
                                                  child: Text('G', style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF4285F4),
                                                  )),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Masuk dengan Google',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: LuvColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text('© 2026 LUVENCE ID', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

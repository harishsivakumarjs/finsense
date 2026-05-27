import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _prog;

  @override
  void initState() {
    super.initState();
    _prog = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  @override
  void dispose() {
    _prog.dispose();
    super.dispose();
  }

  void _navigate() {
    final auth = ref.read(authProvider);
    final isAuth = auth.value?.isAuthenticated ?? false;
    if (mounted) context.go(isAuth ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;

    ref.listen(authProvider, (_, next) {
      if (!next.isLoading) {
        Future.delayed(const Duration(milliseconds: 400), _navigate);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Center content
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: c.teal,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: c.teal.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: Text('F.', style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.easeOut),
                const SizedBox(height: 20),
                Text('FinSense',
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)))
                    .animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 6),
                Text('Elevated financial intelligence',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF94A3B8)))
                    .animate(delay: 350.ms).fadeIn(duration: 400.ms),
              ]),
            ),

            // Progress bar at bottom
            Positioned(
              bottom: 48, left: 40, right: 40,
              child: Column(children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: _prog,
                    builder: (_, __) => FractionallySizedBox(
                      widthFactor: _prog.value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(color: c.teal, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                ).animate(delay: 600.ms).fadeIn(duration: 300.ms),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _loginForm = GlobalKey<FormState>();
  final _regForm = GlobalKey<FormState>();

  // Sign in
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscurePass = true;

  // Sign up
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  String _mode = 'student';
  bool _obscureRegPass = true;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _email.dispose(); _pass.dispose();
    _regName.dispose(); _regEmail.dispose(); _regPass.dispose(); _regConfirm.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString().replaceAll('Exception:', '').trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (mounted && !msg.contains('cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $msg')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_regForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
        name: _regName.text.trim(),
        email: _regEmail.text.trim(),
        password: _regPass.text,
        mode: _mode,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString().replaceAll('Exception:', '').trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: c.teal,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: c.teal.withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: Text('F.', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                const SizedBox(height: 20),
                Text('FinSense', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: c.textPrimary)).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 4),
                Text('Elevated financial intelligence', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textTertiary)).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                const SizedBox(height: 28),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 40 : 10), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
                        child: TabBar(
                          controller: _tabs,
                          indicator: BoxDecoration(color: c.teal, borderRadius: BorderRadius.circular(10)),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: c.textTertiary,
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                          tabs: const [Tab(text: 'Sign in'), Tab(text: 'Sign up')],
                        ),
                      ),

                      // Tab content
                      SizedBox(
                        height: 340,
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _buildSignIn(context, c),
                            _buildSignUp(context, c),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.06),

                const SizedBox(height: 20),
                _buildDivider(c),
                const SizedBox(height: 16),

                // Google Sign-In button
                _GoogleSignInButton(onTap: _loading ? null : _signInWithGoogle, loading: _loading).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 12),

                // Demo mode button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Try demo mode', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.textSecondary, fontWeight: FontWeight.w500)),
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn(BuildContext context, FSColorScheme c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _loginForm,
        child: Column(children: [
          FSTextField(
            label: 'Email address',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
          ),
          const SizedBox(height: 12),
          FSTextField(
            label: 'Password',
            controller: _pass,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.done,
            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
            suffix: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: c.textTertiary),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
              child: Text('Forgot password?', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.teal)),
            ),
          ),
          const SizedBox(height: 12),
          FSButton(label: 'Sign in  →', onPressed: _loading ? null : _login, isLoading: _loading, fullWidth: true),
        ]),
      ),
    );
  }

  Widget _buildSignUp(BuildContext context, FSColorScheme c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _regForm,
        child: Column(children: [
          FSTextField(
            label: 'Full name',
            controller: _regName,
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
          ),
          const SizedBox(height: 12),
          FSTextField(
            label: 'Email address',
            controller: _regEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
          ),
          const SizedBox(height: 12),
          FSTextField(
            label: 'Password',
            controller: _regPass,
            obscureText: _obscureRegPass,
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
            suffix: IconButton(
              icon: Icon(_obscureRegPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: c.textTertiary),
              onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
            ),
          ),
          const SizedBox(height: 12),
          FSTextField(
            label: 'Confirm password',
            controller: _regConfirm,
            obscureText: _obscureRegPass,
            textInputAction: TextInputAction.done,
            validator: (v) => v != _regPass.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 14),
          // Mode selector
          Row(children: [
            _ModeChip(label: 'Student', icon: Icons.school_rounded, selected: _mode == 'student', onTap: () => setState(() => _mode = 'student'), c: c),
            const SizedBox(width: 8),
            _ModeChip(label: 'Professional', icon: Icons.work_rounded, selected: _mode == 'professional', onTap: () => setState(() => _mode = 'professional'), c: c),
          ]),
          const SizedBox(height: 16),
          FSButton(label: 'Create account', onPressed: _loading ? null : _register, isLoading: _loading, fullWidth: true),
        ]),
      ),
    );
  }

  Widget _buildDivider(FSColorScheme c) {
    return Row(children: [
      Expanded(child: Divider(color: c.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
      ),
      Expanded(child: Divider(color: c.border)),
    ]);
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final FSColorScheme c;
  const _ModeChip({required this.label, required this.icon, required this.selected, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.tealDim : c.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? c.teal.withAlpha(100) : c.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? c.teal : c.textTertiary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? c.teal : c.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  const _GoogleSignInButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDE1E6)),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4285F4)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Blue top-right
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -1.57, 1.57, true, paint);
    // Green bottom-right
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 0.0, 1.57, true, paint);
    // Yellow bottom-left
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 1.57, 1.57, true, paint);
    // Red top-left
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 3.14, 1.57, true, paint);
    // White center hole
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

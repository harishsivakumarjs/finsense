import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  String _mode = 'student';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _pass.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [c.teal, c.info], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: c.teal.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Center(
                          child: Text('F.', style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Create account', style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Start your financial journey', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.textSecondary)),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FSTextField(label: 'Full Name', controller: _name, textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null),
                      const SizedBox(height: 14),
                      FSTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                          validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null),
                      const SizedBox(height: 14),
                      FSTextField(label: 'Password', controller: _pass, obscureText: _obscure, textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: c.textTertiary),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          )),
                      const SizedBox(height: 14),
                      FSTextField(label: 'Confirm Password', controller: _confirm, obscureText: _obscure, textInputAction: TextInputAction.done,
                          validator: (v) => v != _pass.text ? 'Passwords do not match' : null),
                      const SizedBox(height: 20),
                      Text('I am a...', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _ModeCard(label: 'Student', icon: Icons.school_rounded, selected: _mode == 'student', onTap: () => setState(() => _mode = 'student'))),
                        const SizedBox(width: 10),
                        Expanded(child: _ModeCard(label: 'Earner', icon: Icons.work_rounded, selected: _mode == 'earner', onTap: () => setState(() => _mode = 'earner'))),
                      ]),
                      const SizedBox(height: 20),
                      FSButton(label: 'Create Account', onPressed: _loading ? null : _register, isLoading: _loading, fullWidth: true),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.textSecondary),
                        children: [
                          TextSpan(text: 'Sign in', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.teal, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
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

class _ModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? c.tealDim : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c.teal.withAlpha(100) : c.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? c.teal : c.textTertiary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? c.teal : c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

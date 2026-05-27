import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FSColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: FSColors.tealDim,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text('F', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: FSColors.teal)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Welcome back', style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, fontWeight: FontWeight.w700, color: FSColors.textPrimary,
                        )),
                        const SizedBox(height: 6),
                        Text('Sign in to your FinSense account', style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: FSColors.textTertiary,
                        )),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),
                  ),
                  const SizedBox(height: 40),
                  FSTextField(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  FSTextField(
                    label: 'Password',
                    controller: _pass,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18, color: FSColors.textTertiary),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FSButton(
                    label: 'Sign In',
                    onPressed: _loading ? null : _login,
                    isLoading: _loading,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textTertiary),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.teal, fontWeight: FontWeight.w600),
                            ),
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
      ),
    );
  }
}

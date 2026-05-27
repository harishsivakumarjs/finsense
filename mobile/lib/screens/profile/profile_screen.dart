import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_bottom_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final isDark = context.isDark;
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value?.user;
    final name = user?.name ?? '';
    final email = user?.email ?? '';
    final mode = user?.mode ?? 'student';
    final initials = user?.initials ?? 'U';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Avatar + identity
        Center(
          child: Column(children: [
            Stack(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.teal,
                    border: Border.all(color: c.teal.withAlpha(80), width: 3),
                  ),
                  child: Center(
                    child: Text(initials, style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.card, border: Border.all(color: c.border)),
                    child: Icon(Icons.camera_alt_rounded, size: 14, color: c.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(width: 6),
              Icon(Icons.verified_rounded, size: 16, color: c.teal),
            ]),
            const SizedBox(height: 4),
            Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(20)),
              child: Text(mode.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.teal, letterSpacing: 0.8)),
            ),
          ]),
        ),
        const SizedBox(height: 28),

        // Appearance
        _SectionHeader(label: 'APPEARANCE'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          label: 'Theme',
          subtitle: isDark ? 'Dark mode' : 'Light mode',
          trailing: Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: c.teal,
            activeTrackColor: c.tealDim,
          ),
        ),
        const SizedBox(height: 20),

        // Account section
        _SectionHeader(label: 'ACCOUNT'),
        const SizedBox(height: 8),
        _SettingsItem(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () => _openChangePassword(context)),
        const SizedBox(height: 8),
        _SettingsItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Switch Mode',
          subtitle: mode == 'student' ? 'Switch to Professional' : 'Switch to Student',
          onTap: () => _confirmSwitchMode(context, mode),
        ),
        const SizedBox(height: 8),
        _SettingsItem(icon: Icons.notifications_outlined, label: 'Notification Preferences', onTap: () {}),
        const SizedBox(height: 20),

        // App section
        _SectionHeader(label: 'APP'),
        const SizedBox(height: 8),
        _SettingsItem(icon: Icons.info_outline_rounded, label: 'App Version', subtitle: '1.0.0', onTap: null),
        const SizedBox(height: 28),

        FSButton(
          label: 'Logout',
          onPressed: () => _confirmLogout(context),
          style: FSButtonStyle.danger,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _openChangePassword(BuildContext context) {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    showFSBottomSheet(
      context: context,
      title: 'Change Password',
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16, left: 20, right: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FSTextField(label: 'Current Password', controller: current, obscureText: true),
            const SizedBox(height: 10),
            FSTextField(label: 'New Password', controller: next, obscureText: true),
            const SizedBox(height: 10),
            FSTextField(label: 'Confirm Password', controller: confirm, obscureText: true),
            const SizedBox(height: 16),
            FSButton(label: 'Save', fullWidth: true, onPressed: () {
              if (next.text != confirm.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
            }),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmSwitchMode(BuildContext context, String currentMode) async {
    final c = context.fsc;
    final newMode = currentMode == 'student' ? 'professional' : 'student';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Switch Mode', style: GoogleFonts.plusJakartaSans(color: c.textPrimary)),
        content: Text('Switch to ${newMode[0].toUpperCase()}${newMode.substring(1)} mode?',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Switch', style: TextStyle(color: c.teal))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).switchMode(newMode);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Switched to $newMode mode')));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final c = context.fsc;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Logout', style: GoogleFonts.plusJakartaSans(color: c.textPrimary)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Logout', style: TextStyle(color: c.negative))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.label, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 20 : 5), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: c.teal),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
          if (subtitle != null) Text(subtitle!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
        ])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsItem({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 20 : 5), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: c.teal),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
            if (subtitle != null) Text(subtitle!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
          ])),
          if (onTap != null) Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: 18),
        ]),
      ),
    );
  }
}

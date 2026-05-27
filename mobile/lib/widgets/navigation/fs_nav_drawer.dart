import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';

class FSNavDrawer extends ConsumerWidget {
  final String currentRoute;
  const FSNavDrawer({super.key, required this.currentRoute});

  static const _navItems = [
    (Icons.home_rounded, Icons.home_outlined, 'Dashboard', '/dashboard'),
    (Icons.arrow_circle_up_rounded, Icons.arrow_circle_up_outlined, 'Income', '/income'),
    (Icons.arrow_circle_down_rounded, Icons.arrow_circle_down_outlined, 'Expenses', '/expenses'),
    (Icons.credit_card_rounded, Icons.credit_card_outlined, 'Debt', '/debt'),
    (Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'Investments', '/investments'),
    (Icons.candlestick_chart_rounded, Icons.candlestick_chart_outlined, 'Trading', '/trading'),
    (Icons.verified_user_rounded, Icons.verified_user_outlined, 'Insurance', '/insurance'),
    (Icons.video_library_rounded, Icons.video_library_outlined, 'Creator Hub', '/creator'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Tax Planner', '/tax'),
    (Icons.show_chart_rounded, Icons.show_chart_rounded, 'Net Worth', '/networth'),
    (Icons.people_rounded, Icons.people_outline_rounded, 'Friends Ledger', '/friends'),
    (Icons.calculate_rounded, Icons.calculate_outlined, 'Simulator', '/simulator'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fsc;
    final isDark = context.isDark;
    final user = ref.watch(authProvider).value?.user;
    final name = user?.name ?? '';
    final email = user?.email ?? '';
    final initials = user?.initials ?? 'U';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.80,
      backgroundColor: c.card,
      child: Column(
        children: [
          // Header with logo
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: c.teal, borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text('F.', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('FinSense', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: c.textTertiary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: c.border, height: 1),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final (activeIcon, inactiveIcon, label, route) = _navItems[i];
                final active = currentRoute == route;
                return _NavItem(
                  activeIcon: activeIcon,
                  inactiveIcon: inactiveIcon,
                  label: label,
                  active: active,
                  onTap: () {
                    Navigator.pop(context);
                    if (!active) context.go(route);
                  },
                );
              },
            ),
          ),

          Divider(color: c.border, height: 1),

          // Bottom user section
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User profile row
                  GestureDetector(
                    onTap: () { Navigator.pop(context); context.push('/profile'); },
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.teal),
                          child: Center(
                            child: Text(initials, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Action row
                  Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.settings_outlined,
                        tooltip: 'Settings',
                        onTap: () { Navigator.pop(context); context.push('/profile'); },
                        c: c,
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        tooltip: 'Toggle theme',
                        onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                        c: c,
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.logout_rounded,
                        tooltip: 'Logout',
                        onTap: () => _confirmLogout(context, ref, c),
                        c: c,
                        color: c.negative,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, FSColorScheme c) async {
    Navigator.pop(context);
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
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.activeIcon, required this.inactiveIcon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? c.tealDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(active ? activeIcon : inactiveIcon, size: 19, color: active ? c.teal : c.textSecondary),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? c.teal : c.textSecondary,
            ),
          ),
          if (active) ...[
            const Spacer(),
            Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: c.teal)),
          ],
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final FSColorScheme c;
  final Color? color;
  const _ActionBtn({required this.icon, required this.tooltip, required this.onTap, required this.c, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? c.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: (color != null) ? color!.withAlpha(15) : c.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (color != null) ? color!.withAlpha(60) : c.border),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

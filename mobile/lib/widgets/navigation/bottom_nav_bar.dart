import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';

class FSBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const FSBottomNavBar({super.key, required this.currentIndex});

  // Routes: 0=Income, 1=Expenses, 2=Home(FAB), 3=NetWorth, 4=More
  static const _routes = ['/income', '/expenses', '/dashboard', '/networth', ''];

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 64 + bottomPad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bar background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.border.withAlpha(50))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(context.isDark ? 40 : 10),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(bottom: bottomPad),
              child: Row(
                children: [
                  _NavItem(icon: Icons.arrow_circle_up_outlined, activeIcon: Icons.arrow_circle_up_rounded, label: 'Income', index: 0, currentIndex: currentIndex, onTap: () => context.go(_routes[0])),
                  _NavItem(icon: Icons.arrow_circle_down_outlined, activeIcon: Icons.arrow_circle_down_rounded, label: 'Expenses', index: 1, currentIndex: currentIndex, onTap: () => context.go(_routes[1])),
                  const Expanded(child: SizedBox()), // space for center FAB
                  _NavItem(icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart_rounded, label: 'Net Worth', index: 3, currentIndex: currentIndex, onTap: () => context.go(_routes[3])),
                  _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'More', index: 4, currentIndex: currentIndex, onTap: () => _showMoreDrawer(context)),
                ],
              ),
            ),
          ),
          // Center floating home button
          Positioned(
            top: -18,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => context.go('/dashboard'),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == 2 ? c.teal : c.card,
                    border: Border.all(
                      color: currentIndex == 2 ? c.teal : c.border,
                      width: currentIndex == 2 ? 0 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.teal.withAlpha(currentIndex == 2 ? 80 : 40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    currentIndex == 2 ? Icons.home_rounded : Icons.home_outlined,
                    color: currentIndex == 2 ? Colors.white : c.teal,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.fsc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MoreSheet(onNavigate: (route) {
        Navigator.pop(context);
        context.go(route);
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final active = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 22,
              color: active ? c.teal : c.textTertiary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? c.teal : c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSheet extends ConsumerWidget {
  final void Function(String) onNavigate;
  const _MoreSheet({required this.onNavigate});

  static const _items = [
    (Icons.credit_card_rounded, 'Debt', '/debt'),
    (Icons.pie_chart_rounded, 'Investments', '/investments'),
    (Icons.trending_up_rounded, 'Trading', '/trading'),
    (Icons.video_library_rounded, 'Creator', '/creator'),
    (Icons.people_rounded, 'Friends', '/friends'),
    (Icons.receipt_long_rounded, 'Tax', '/tax'),
    (Icons.calculate_rounded, 'Simulator', '/simulator'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fsc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.textTertiary.withAlpha(60), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
            children: _items.map((item) => GestureDetector(
              onTap: () => onNavigate(item.$3),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.$1, color: c.teal, size: 17),
                    ),
                    const SizedBox(height: 5),
                    Text(item.$2, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textSecondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class FSBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const FSBottomNavBar({super.key, required this.currentIndex});

  static const _routes = ['/dashboard', '/income', '/investments', '/insurance', '/more'];
  static const _labels = ['Home', 'Money', 'Portfolio', 'Insurance', 'More'];
  static const _icons = [
    Icons.home_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.pie_chart_rounded,
    Icons.security_rounded,
    Icons.grid_view_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FSColors.card,
        border: Border(top: BorderSide(color: FSColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_routes.length, (i) => Expanded(
              child: GestureDetector(
                onTap: () {
                  if (i == 4) {
                    _showMoreDrawer(context);
                  } else {
                    context.go(_routes[i]);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[i],
                      size: 22,
                      color: currentIndex == i ? FSColors.teal : FSColors.textTertiary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _labels[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: currentIndex == i ? FontWeight.w600 : FontWeight.w400,
                        color: currentIndex == i ? FSColors.teal : FSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ),
      ),
    );
  }

  void _showMoreDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FSColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreSheet(onNavigate: (route) {
        Navigator.pop(context);
        context.go(route);
      }),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  final void Function(String) onNavigate;
  const _MoreSheet({required this.onNavigate});

  static const _items = [
    (Icons.credit_card_rounded, 'Debt', '/debt'),
    (Icons.video_library_rounded, 'Creator', '/creator'),
    (Icons.receipt_long_rounded, 'Tax', '/tax'),
    (Icons.show_chart_rounded, 'Net Worth', '/networth'),
    (Icons.people_rounded, 'Friends', '/friends'),
    (Icons.calculate_rounded, 'Simulator', '/simulator'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: FSColors.textTertiary.withAlpha(80), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('More', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: FSColors.textPrimary)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: _items.map((item) => GestureDetector(
              onTap: () => onNavigate(item.$3),
              child: Container(
                decoration: BoxDecoration(
                  color: FSColors.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FSColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: FSColors.teal, size: 22),
                    const SizedBox(height: 6),
                    Text(item.$2, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textSecondary)),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/networth_provider.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_amount_display.dart';
import '../../widgets/charts/area_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class NetworthScreen extends ConsumerStatefulWidget {
  const NetworthScreen({super.key});
  @override
  ConsumerState<NetworthScreen> createState() => _NetworthScreenState();
}

class _NetworthScreenState extends ConsumerState<NetworthScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _milestones = [100000.0, 500000.0, 1000000.0, 2500000.0, 5000000.0, 10000000.0];
  static const _milestoneLabels = ['₹1L', '₹5L', '₹10L', '₹25L', '₹50L', '₹1Cr'];

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final nwAsync = ref.watch(networthProvider);
    final histAsync = ref.watch(networthHistoryProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/networth'),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: const Text('Net Worth'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () => ref.read(networthProvider.notifier).refresh(),
        child: nwAsync.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (data) {
            final netWorth = (data['total_net_worth'] as num?)?.toDouble() ?? 0;
            final assets = (data['total_assets'] as num?)?.toDouble() ?? 0;
            final liabilities = (data['total_liabilities'] as num?)?.toDouble() ?? 0;
            final changeMonth = (data['change_this_month'] as num?)?.toDouble() ?? 0;
            final assetsList = (data['assets'] as List? ?? []).cast<Map<String, dynamic>>();
            final liabilsList = (data['liabilities'] as List? ?? []).cast<Map<String, dynamic>>();

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              // Hero card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Text('NET WORTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.teal, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(formatINR(netWorth), style: GoogleFonts.jetBrainsMono(fontSize: 34, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.amountColor(changeMonth).withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(changeMonth >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: c.amountColor(changeMonth)),
                      const SizedBox(width: 3),
                      FSAmountDisplay(amount: changeMonth, fontSize: 12, compact: true),
                      Text(' this month', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.amountColor(changeMonth))),
                    ]),
                  ),
                ]),
              ).animate().fadeIn(),
              const SizedBox(height: 16),

              histAsync.when(
                loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const SizedBox(),
                data: (history) => FSAreaChart(
                  values: history.map((p) => p.netWorth).toList(),
                  labels: history.map((p) => p.month).toList(),
                  color: c.teal,
                  height: 180,
                ).animate(delay: 80.ms).fadeIn(),
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _NwSummaryCard(label: 'Total Assets', value: assets, color: c.positive, icon: Icons.account_balance_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _NwSummaryCard(label: 'Liabilities', value: liabilities, color: c.negative, icon: Icons.credit_card_outlined)),
              ]).animate(delay: 120.ms).fadeIn(),
              const SizedBox(height: 16),

              // Assets Breakdown Card
              if (assetsList.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.positive.withAlpha(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 25 : 6), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.account_balance_outlined, size: 14, color: c.positive),
                      const SizedBox(width: 6),
                      Text('ASSETS BREAKDOWN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.positive, letterSpacing: 1)),
                      const Spacer(),
                      Text(formatINRCompact(assets), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: c.positive)),
                    ]),
                    const SizedBox(height: 12),
                    ...assetsList.map((a) {
                      final v = (a['value'] as num?)?.toDouble() ?? 0;
                      final pct = assets > 0 ? (v / assets).clamp(0.0, 1.0) : 0.0;
                      return _NwBreakdownRow(name: a['name'] as String? ?? '', value: v, pct: pct, color: c.positive);
                    }),
                  ]),
                ).animate(delay: 140.ms).fadeIn(),
                const SizedBox(height: 12),
              ],

              // Liabilities Breakdown Card
              if (liabilsList.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.negative.withAlpha(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 25 : 6), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.credit_card_outlined, size: 14, color: c.negative),
                      const SizedBox(width: 6),
                      Text('LIABILITIES BREAKDOWN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.negative, letterSpacing: 1)),
                      const Spacer(),
                      Text(formatINRCompact(liabilities), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: c.negative)),
                    ]),
                    const SizedBox(height: 12),
                    ...liabilsList.map((l) {
                      final v = (l['value'] as num?)?.toDouble() ?? 0;
                      final pct = liabilities > 0 ? (v / liabilities).clamp(0.0, 1.0) : 0.0;
                      return _NwBreakdownRow(name: l['name'] as String? ?? '', value: v, pct: pct, color: c.negative);
                    }),
                  ]),
                ).animate(delay: 160.ms).fadeIn(),
                const SizedBox(height: 16),
              ],

              Text('MILESTONES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 10),
              ..._milestones.asMap().entries.map((entry) {
                final target = entry.value;
                final label = _milestoneLabels[entry.key];
                final achieved = netWorth >= target;
                final progress = achieved ? 1.0 : (netWorth / target).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: achieved ? c.teal.withAlpha(60) : c.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: achieved ? c.tealDim : c.surface, shape: BoxShape.circle),
                      child: Icon(achieved ? Icons.check_rounded : Icons.flag_rounded, size: 16, color: achieved ? c.teal : c.textTertiary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: achieved ? c.teal : c.textPrimary)),
                      const SizedBox(height: 5),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: c.surface, color: achieved ? c.teal : c.info, minHeight: 5)),
                    ])),
                  ]),
                );
              }),
              const SizedBox(height: 16),
              FSButton(label: 'Take Snapshot', onPressed: () async {
                await ref.read(networthProvider.notifier).takeSnapshot();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snapshot taken')));
              }, style: FSButtonStyle.ghost, fullWidth: true),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 3),
    );
  }
}

class _NwSummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _NwSummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 25 : 6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 8),
        Text(formatINRCompact(value), style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
      ]),
    );
  }
}

class _NwBreakdownRow extends StatelessWidget {
  final String name;
  final double value;
  final double pct;
  final Color color;
  const _NwBreakdownRow({required this.name, required this.value, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(formatINRCompact(value), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, backgroundColor: c.surface, color: color, minHeight: 5),
        ),
      ]),
    );
  }
}


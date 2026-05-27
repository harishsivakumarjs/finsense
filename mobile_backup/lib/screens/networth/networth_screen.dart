import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/networth_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_amount_display.dart';
import '../../widgets/charts/area_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class NetworthScreen extends ConsumerStatefulWidget {
  const NetworthScreen({super.key});
  @override
  ConsumerState<NetworthScreen> createState() => _NetworthScreenState();
}

class _NetworthScreenState extends ConsumerState<NetworthScreen> {
  static const _milestones = [100000.0, 500000.0, 1000000.0, 2500000.0, 5000000.0, 10000000.0];
  static const _milestoneLabels = ['₹1L', '₹5L', '₹10L', '₹25L', '₹50L', '₹1Cr'];

  @override
  Widget build(BuildContext context) {
    final nwAsync = ref.watch(networthProvider);
    final histAsync = ref.watch(networthHistoryProvider);

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: const Text('Net Worth')),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () => ref.read(networthProvider.notifier).refresh(),
        child: nwAsync.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList()]),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) {
            final netWorth = (data['total_net_worth'] as num?)?.toDouble() ?? 0;
            final assets = (data['total_assets'] as num?)?.toDouble() ?? 0;
            final liabilities = (data['total_liabilities'] as num?)?.toDouble() ?? 0;
            final changeMonth = (data['change_this_month'] as num?)?.toDouble() ?? 0;
            final assetsList = (data['assets'] as List? ?? []).cast<Map<String, dynamic>>();
            final liabilsList = (data['liabilities'] as List? ?? []).cast<Map<String, dynamic>>();

            return ListView(padding: const EdgeInsets.all(16), children: [
              // Big net worth
              Center(child: Column(children: [
                Text('NET WORTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Text(formatINR(netWorth), style: GoogleFonts.jetBrainsMono(fontSize: 32, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(changeMonth >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: FSColors.amountColor(changeMonth)),
                  const SizedBox(width: 4),
                  FSAmountDisplay(amount: changeMonth, fontSize: 13, compact: true),
                  Text(' this month', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textTertiary)),
                ]),
              ])).animate().fadeIn(),
              const SizedBox(height: 20),

              // History chart
              histAsync.when(
                loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: FSColors.teal, strokeWidth: 2))),
                error: (_, __) => const SizedBox(),
                data: (history) => FSAreaChart(
                  values: history.map((p) => p.netWorth).toList(),
                  labels: history.map((p) => p.month).toList(),
                  color: FSColors.teal,
                  height: 180,
                ).animate(delay: 100.ms).fadeIn(),
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: FSMetricCard(label: 'Total Assets', value: assets, accentColor: FSColors.positive)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Liabilities', value: liabilities, accentColor: FSColors.negative)),
              ]).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 16),

              // Assets
              if (assetsList.isNotEmpty) ...[
                Text('ASSETS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ...assetsList.map((a) => _NwRow(name: a['name'] as String? ?? '', value: (a['value'] as num?)?.toDouble() ?? 0, color: FSColors.positive)),
                const SizedBox(height: 12),
              ],

              // Liabilities
              if (liabilsList.isNotEmpty) ...[
                Text('LIABILITIES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ...liabilsList.map((l) => _NwRow(name: l['name'] as String? ?? '', value: (l['value'] as num?)?.toDouble() ?? 0, color: FSColors.negative)),
                const SizedBox(height: 16),
              ],

              // Milestones
              Text('MILESTONES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              ..._milestones.asMap().entries.map((entry) {
                final target = entry.value;
                final label = _milestoneLabels[entry.key];
                final achieved = netWorth >= target;
                final progress = achieved ? 1.0 : (netWorth / target).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: achieved ? FSColors.teal.withAlpha(60) : FSColors.border)),
                  child: Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: achieved ? FSColors.tealDim : FSColors.tertiary, shape: BoxShape.circle),
                        child: Icon(achieved ? Icons.check_rounded : Icons.flag_rounded, size: 16, color: achieved ? FSColors.teal : FSColors.textTertiary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: achieved ? FSColors.teal : FSColors.textPrimary)),
                      const SizedBox(height: 4),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: FSColors.tertiary, color: achieved ? FSColors.teal : FSColors.info, minHeight: 4)),
                    ])),
                  ]),
                );
              }),
              const SizedBox(height: 16),
              FSButton(
                label: 'Take Snapshot',
                onPressed: () async {
                  await ref.read(networthProvider.notifier).takeSnapshot();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snapshot taken')));
                },
                style: FSButtonStyle.ghost,
                fullWidth: true,
              ),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }
}

class _NwRow extends StatelessWidget {
  final String name;
  final double value;
  final Color color;
  const _NwRow({required this.name, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(formatINRCompact(value), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

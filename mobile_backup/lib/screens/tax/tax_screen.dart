import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/tax_model.dart';
import '../../providers/tax_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_alert_card.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key});
  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(taxSummaryProvider);
    final advanceAsync = ref.watch(advanceTaxProvider);
    final year = DateTime.now().month >= 4 ? DateTime.now().year : DateTime.now().year - 1;

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: Text('Tax — FY $year-${(year + 1).toString().substring(2)}')),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () async {
          ref.invalidate(taxSummaryProvider);
          ref.invalidate(advanceTaxProvider);
          ref.invalidate(taxDeductionsProvider);
        },
        child: summaryAsync.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList()]),
          error: (e, _) => Center(child: Text('Error loading tax data')),
          data: (summary) {
            final estimated = (summary['estimated_due'] as num?)?.toDouble() ?? 0;
            final paid = (summary['paid'] as num?)?.toDouble() ?? 0;
            final netPayable = (summary['net_payable'] as num?)?.toDouble() ?? 0;
            final deductions = summary['deductions'] as Map<String, dynamic>? ?? {};
            final d80C = (deductions['80C'] as num?)?.toDouble() ?? 0;
            final d80D = (deductions['80D'] as num?)?.toDouble() ?? 0;
            final d80CCD = (deductions['80CCD'] as num?)?.toDouble() ?? 0;
            final suggestions = (summary['suggestions'] as List? ?? [])
                .map((e) => TaxSuggestion.fromJson(e as Map<String, dynamic>)).toList();

            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Estimated Due', value: estimated, accentColor: FSColors.warning)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Paid', value: paid, accentColor: FSColors.positive)),
              ]).animate().fadeIn(),
              const SizedBox(height: 10),
              FSMetricCard(label: 'Net Payable', value: netPayable, accentColor: netPayable > 0 ? FSColors.negative : FSColors.positive).animate(delay: 80.ms).fadeIn(),
              const SizedBox(height: 16),

              // Deductions
              Text('DEDUCTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              _DeductionBar(label: '80C', value: d80C, limit: 150000, color: FSColors.teal),
              const SizedBox(height: 8),
              _DeductionBar(label: '80D', value: d80D, limit: 25000, color: FSColors.purple),
              const SizedBox(height: 8),
              _DeductionBar(label: '80CCD', value: d80CCD, limit: 50000, color: FSColors.info),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _openAddDeduction(context),
                icon: const Icon(Icons.add_rounded, size: 14, color: FSColors.teal),
                label: Text('Add Deduction', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.teal)),
              ),
              const SizedBox(height: 16),

              // Advance Tax
              Text('ADVANCE TAX CALENDAR', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              advanceAsync.when(
                loading: () => const FSSkeletonList(count: 4),
                error: (_, __) => const SizedBox(),
                data: (payments) => Column(children: payments.map((p) => _AdvanceTaxCard(payment: p, onPay: () => _markPaid(p.id))).toList()),
              ),
              const SizedBox(height: 16),

              // Suggestions
              if (suggestions.isNotEmpty) ...[
                Text('TAX SAVING SUGGESTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ...suggestions.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FSAlertCard(message: '${s.title} — Save ${formatINRCompact(s.potentialSaving)}', color: FSColors.warning),
                )),
              ],
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }

  Future<void> _markPaid(int id) async {
    await ref.read(advanceTaxProvider.notifier).markPaid(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as paid')));
  }

  void _openAddDeduction(BuildContext context) {
    final amount = TextEditingController();
    final desc = TextEditingController();
    String section = '80C';
    showFSBottomSheet(context: context, title: 'Add Deduction', builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16, left: 20, right: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FSChipGroup(options: const ['80C','80D','80CCD','other'], selected: section, onSelect: (v) => ss(() => section = v)),
          const SizedBox(height: 12),
          FSTextField(label: 'Amount', controller: amount, isAmount: true),
          const SizedBox(height: 10),
          FSTextField(label: 'Description', controller: desc),
          const SizedBox(height: 16),
          FSButton(label: 'Add Deduction', onPressed: () async {
            await ref.read(taxDeductionsProvider.notifier).add({'section': section, 'amount': double.tryParse(amount.text) ?? 0, 'description': desc.text});
            if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deduction added'))); }
          }, fullWidth: true),
          const SizedBox(height: 8),
        ]),
      ),
    ));
  }
}

class _DeductionBar extends StatelessWidget {
  final String label;
  final double value;
  final double limit;
  final Color color;
  const _DeductionBar({required this.label, required this.value, required this.limit, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = (value / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: FSColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Section $label', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: FSColors.textPrimary)),
          Text('${formatINRCompact(value)} / ${formatINRCompact(limit)}', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: fraction, backgroundColor: FSColors.tertiary, color: color, minHeight: 6)),
        const SizedBox(height: 4),
        Text('${((1 - fraction) * limit).toStringAsFixed(0)} remaining', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.textTertiary)),
      ]),
    );
  }
}

class _AdvanceTaxCard extends StatelessWidget {
  final AdvanceTaxPayment payment;
  final VoidCallback onPay;
  const _AdvanceTaxCard({required this.payment, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final days = payment.daysRemaining;
    final urgent = days >= 0 && days <= 15;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FSColors.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: payment.isPaid ? FSColors.positive.withAlpha(40) : (urgent ? FSColors.warning.withAlpha(60) : FSColors.border)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(
            color: payment.isPaid ? FSColors.positive.withAlpha(30) : FSColors.amberDim,
            shape: BoxShape.circle),
            child: Icon(payment.isPaid ? Icons.check_rounded : Icons.calendar_today_rounded,
                size: 18, color: payment.isPaid ? FSColors.positive : FSColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.deadline, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: FSColors.textPrimary)),
          Text(payment.isPaid ? 'Paid' : (days >= 0 ? '$days days remaining' : 'Overdue'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: payment.isPaid ? FSColors.positive : (days < 0 ? FSColors.negative : FSColors.textTertiary))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatINRCompact(payment.amountDue), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
          if (!payment.isPaid) ...[
            const SizedBox(height: 4),
            GestureDetector(onTap: onPay, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: FSColors.tealDim, borderRadius: BorderRadius.circular(6)),
                child: Text('Mark Paid', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.teal, fontWeight: FontWeight.w600)))),
          ],
        ]),
      ]),
    );
  }
}

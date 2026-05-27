import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
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
import '../../widgets/navigation/fs_nav_drawer.dart';

class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key});
  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final summaryAsync = ref.watch(taxSummaryProvider);
    final advanceAsync = ref.watch(advanceTaxProvider);
    final year = DateTime.now().month >= 4 ? DateTime.now().year : DateTime.now().year - 1;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/tax'),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: Text('Tax — FY $year-${(year + 1).toString().substring(2)}'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () async {
          ref.invalidate(taxSummaryProvider);
          ref.invalidate(advanceTaxProvider);
          ref.invalidate(taxDeductionsProvider);
        },
        child: summaryAsync.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error loading tax data', style: GoogleFonts.plusJakartaSans(color: c.negative))),
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

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Estimated Due', value: estimated, accentColor: c.warning)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Paid', value: paid, accentColor: c.positive)),
              ]).animate().fadeIn(),
              const SizedBox(height: 10),
              FSMetricCard(label: 'Net Payable', value: netPayable, accentColor: netPayable > 0 ? c.negative : c.positive)
                  .animate(delay: 80.ms).fadeIn(),
              const SizedBox(height: 16),

              Text('DEDUCTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              _DeductionBar(label: '80C', value: d80C, limit: 150000, color: c.teal),
              const SizedBox(height: 8),
              _DeductionBar(label: '80D', value: d80D, limit: 25000, color: c.purple),
              const SizedBox(height: 8),
              _DeductionBar(label: '80CCD', value: d80CCD, limit: 50000, color: c.info),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => _openAddDeduction(context),
                icon: Icon(Icons.add_rounded, size: 14, color: c.teal),
                label: Text('Add Deduction', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.teal)),
              ),
              const SizedBox(height: 12),

              Text('ADVANCE TAX CALENDAR', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              advanceAsync.when(
                loading: () => const FSSkeletonList(count: 4),
                error: (_, __) => _defaultAdvanceTaxCalendar(context),
                data: (payments) {
                  final list = payments.isNotEmpty ? payments : _defaultInstallments();
                  return Column(children: list.map((p) => _AdvanceTaxCard(payment: p, onPay: () => _markPaid(p.id))).toList());
                },
              ),
              const SizedBox(height: 16),

              if (suggestions.isNotEmpty) ...[
                Text('TAX SAVING SUGGESTIONS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FSAlertCard(message: '${s.title} — Save ${formatINRCompact(s.potentialSaving)}'),
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

  List<AdvanceTaxPayment> _defaultInstallments() => [
    AdvanceTaxPayment(id: '1', deadline: '2026-06-15', amountDue: 0, isPaid: false),
    AdvanceTaxPayment(id: '2', deadline: '2026-09-15', amountDue: 0, isPaid: false),
    AdvanceTaxPayment(id: '3', deadline: '2026-12-15', amountDue: 0, isPaid: false),
    AdvanceTaxPayment(id: '4', deadline: '2027-03-15', amountDue: 0, isPaid: false),
  ];

  Widget _defaultAdvanceTaxCalendar(BuildContext context) => Column(
    children: _defaultInstallments().map((p) => _AdvanceTaxCard(payment: p, onPay: () {})).toList(),
  );

  Future<void> _markPaid(String id) async {
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
          FSChipGroup(options: const ['80C', '80D', '80CCD', 'other'], selected: section, onSelect: (v) => ss(() => section = v)),
          const SizedBox(height: 12),
          FSTextField(label: 'Amount', controller: amount, isAmount: true),
          const SizedBox(height: 10),
          FSTextField(label: 'Description', controller: desc),
          const SizedBox(height: 16),
          FSButton(label: 'Add Deduction', onPressed: () async {
            await ref.read(taxDeductionsProvider.notifier).add({
              'section': section,
              'amount': double.tryParse(amount.text) ?? 0,
              'description': desc.text,
            });
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deduction added')));
            }
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
    final c = context.fsc;
    final fraction = (value / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Section $label', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary)),
          Text('${formatINRCompact(value)} / ${formatINRCompact(limit)}', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: fraction, backgroundColor: c.surface, color: color, minHeight: 6)),
        const SizedBox(height: 4),
        Text('${formatINRCompact((1 - fraction) * limit)} remaining', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
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
    final c = context.fsc;
    final days = payment.daysRemaining;
    final urgent = days >= 0 && days <= 15;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: payment.isPaid ? c.positive.withAlpha(40) : (urgent ? c.warning.withAlpha(60) : c.border)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: payment.isPaid ? c.greenDim : c.amberDim, shape: BoxShape.circle),
          child: Icon(payment.isPaid ? Icons.check_rounded : Icons.calendar_today_rounded,
              size: 18, color: payment.isPaid ? c.positive : c.warning),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.deadline, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
          Text(
            payment.isPaid ? 'Paid' : (days >= 0 ? '$days days remaining' : 'Overdue'),
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: payment.isPaid ? c.positive : (days < 0 ? c.negative : c.textTertiary)),
          ),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatINRCompact(payment.amountDue), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary)),
          if (!payment.isPaid) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onPay,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(6)),
                child: Text('Mark Paid', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.teal, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/investment_model.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/charts/donut_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  static const _typeColors = {
    'mutual_fund': FSColors.teal, 'gold': FSColors.warning,
    'silver': FSColors.textSecondary, 'land': FSColors.purple,
    'fd': FSColors.info, 'ppf': FSColors.positive,
    'stocks': FSColors.negative, 'other': FSColors.textTertiary,
  };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(investmentProvider);

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: const Text('Investments')),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () => ref.read(investmentProvider.notifier).refresh(),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList()]),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (investments) {
            final totalInvested = investments.fold(0.0, (s, i) => s + i.investedAmount);
            final totalCurrent = investments.fold(0.0, (s, i) => s + i.currentValue);
            final gainLoss = totalCurrent - totalInvested;
            final gainPct = totalInvested > 0 ? gainLoss / totalInvested * 100 : 0.0;

            final allocationMap = <String, double>{};
            for (final inv in investments) allocationMap[inv.assetType] = (allocationMap[inv.assetType] ?? 0) + inv.currentValue;
            final sections = allocationMap.entries.map((e) => DonutSection(
                label: e.key, value: e.value, color: _typeColors[e.key] ?? FSColors.textTertiary)).toList();

            final grouped = <String, List<InvestmentModel>>{};
            for (final i in investments) grouped.putIfAbsent(i.assetType, () => []).add(i);

            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Current Value', value: totalCurrent, accentColor: FSColors.teal)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Total Gain/Loss', value: gainLoss, accentColor: FSColors.amountColor(gainLoss))),
              ]).animate().fadeIn(),
              const SizedBox(height: 10),
              FSMetricCard(label: 'Total Invested', value: totalInvested, accentColor: FSColors.info,
                  subtitle: '${gainPct.toStringAsFixed(1)}% return').animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 16),
              if (sections.isNotEmpty) ...[
                Center(child: FSDonutChart(sections: sections, centerLabel: 'Portfolio', centerValue: totalCurrent)).animate(delay: 150.ms).fadeIn(),
                const SizedBox(height: 16),
              ],
              if (investments.isEmpty)
                const FSEmptyState(icon: Icons.pie_chart_rounded, title: 'No investments', subtitle: 'Start tracking your portfolio')
              else
                ...grouped.entries.expand((entry) => [
                  Padding(padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _typeColors[entry.key] ?? FSColors.textTertiary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(entry.key.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: FSColors.textTertiary)),
                      ])),
                  ...entry.value.map((inv) => _InvestmentCard(inv: inv,
                      onEdit: () => _openSheet(context, inv: inv),
                      onUpdateValue: () => _openUpdateValue(context, inv),
                      onDelete: () => _delete(inv.id))),
                ]),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openSheet(context), child: const Icon(Icons.add_rounded)),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 2),
    );
  }

  Future<void> _delete(int id) async { await ref.read(investmentProvider.notifier).remove(id); }

  void _openSheet(BuildContext context, {InvestmentModel? inv}) {
    showFSBottomSheet(context: context, title: inv == null ? 'New Investment' : 'Edit Investment',
        builder: (_) => _AddInvestmentSheet(inv: inv, onSave: (data) async {
          if (inv == null) await ref.read(investmentProvider.notifier).add(data);
          else await ref.read(investmentProvider.notifier).edit(inv.id, data);
        }));
  }

  void _openUpdateValue(BuildContext context, InvestmentModel inv) {
    final ctrl = TextEditingController(text: inv.currentValue.toString());
    showFSBottomSheet(context: context, title: 'Update Value',
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FSTextField(label: 'Current Value', controller: ctrl, isAmount: true),
            const SizedBox(height: 16),
            FSButton(label: 'Update', onPressed: () async {
              final v = double.tryParse(ctrl.text) ?? 0;
              await ref.read(investmentProvider.notifier).updateValue(inv.id, v);
              if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Value updated'))); }
            }, fullWidth: true),
            const SizedBox(height: 8),
          ]),
        ));
  }
}

class _InvestmentCard extends StatelessWidget {
  final InvestmentModel inv;
  final VoidCallback onEdit;
  final VoidCallback onUpdateValue;
  final VoidCallback onDelete;
  const _InvestmentCard({required this.inv, required this.onEdit, required this.onUpdateValue, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final gainColor = FSColors.amountColor(inv.gainLoss);
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: FSColors.border)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(inv.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: FSColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (inv.isLtcg) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: FSColors.tealDim, borderRadius: BorderRadius.circular(4)),
                  child: Text('LTCG', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: FSColors.teal, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text('Invested: ${formatINRCompact(inv.investedAmount)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
              const SizedBox(width: 8),
              Text('→', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
              const SizedBox(width: 8),
              Text(formatINRCompact(inv.currentValue), style: GoogleFonts.jetBrainsMono(fontSize: 12, color: FSColors.textPrimary, fontWeight: FontWeight.w500)),
            ]),
            Text('${inv.daysHeld} days held', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
          ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatINRCompact(inv.gainLoss), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: gainColor)),
            Text('${inv.gainLossPct.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: gainColor)),
            const SizedBox(height: 4),
            GestureDetector(onTap: onUpdateValue, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: FSColors.tealDim, borderRadius: BorderRadius.circular(6)),
              child: Text('Update', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.teal, fontWeight: FontWeight.w600)),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _AddInvestmentSheet extends ConsumerStatefulWidget {
  final InvestmentModel? inv;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddInvestmentSheet({this.inv, required this.onSave});
  @override
  ConsumerState<_AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends ConsumerState<_AddInvestmentSheet> {
  final _name = TextEditingController();
  final _invested = TextEditingController();
  final _current = TextEditingController();
  final _qty = TextEditingController();
  String _assetType = 'mutual_fund';
  String _taxSection = 'none';
  DateTime _purchaseDate = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.inv != null) {
      final i = widget.inv!;
      _name.text = i.name; _invested.text = i.investedAmount.toString();
      _current.text = i.currentValue.toString(); _qty.text = i.quantity.toString();
      _assetType = i.assetType; _taxSection = i.taxSection ?? 'none';
      _purchaseDate = DateTime.tryParse(i.purchaseDate) ?? DateTime.now();
    }
  }

  @override
  void dispose() { _name.dispose(); _invested.dispose(); _current.dispose(); _qty.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'asset_type': _assetType, 'name': _name.text,
        'invested_amount': double.tryParse(_invested.text) ?? 0,
        'current_value': double.tryParse(_current.text) ?? 0,
        'quantity': double.tryParse(_qty.text) ?? 1,
        'unit': 'units',
        'purchase_date': _purchaseDate.toIso8601String().split('T')[0],
        if (_taxSection != 'none') 'tax_section': _taxSection,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Investment saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Asset Type', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
        const SizedBox(height: 8),
        FSChipGroup(options: const ['mutual_fund','gold','silver','land','fd','ppf','stocks','other'], selected: _assetType, onSelect: (v) => setState(() => _assetType = v)),
        const SizedBox(height: 12),
        FSTextField(label: 'Name', controller: _name),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Invested', controller: _invested, isAmount: true)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Current Value', controller: _current, isAmount: true)),
        ]),
        const SizedBox(height: 10),
        FSTextField(label: 'Quantity', controller: _qty, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        GestureDetector(onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _purchaseDate, firstDate: DateTime(2000), lastDate: DateTime.now());
          if (d != null) setState(() => _purchaseDate = d);
        }, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10), border: Border.all(color: FSColors.border)),
          child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: FSColors.textTertiary), const SizedBox(width: 8), Text(formatDate(_purchaseDate), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FSColors.textPrimary))]),
        )),
        const SizedBox(height: 12),
        Text('Tax Section', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
        const SizedBox(height: 8),
        FSChipGroup(options: const ['none','80C','80D','80CCD'], selected: _taxSection, onSelect: (v) => setState(() => _taxSection = v)),
        const SizedBox(height: 16),
        FSButton(label: widget.inv == null ? 'Add Investment' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
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
import '../../widgets/navigation/fs_nav_drawer.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, Color> _typeColors(BuildContext context) {
    final c = context.fsc;
    return {
      'mutual_fund': c.teal, 'gold': c.warning,
      'silver': c.textSecondary, 'land': c.purple,
      'fd': c.info, 'ppf': c.positive,
      'stocks': c.negative, 'other': c.textTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final async = ref.watch(investmentProvider);
    final colors = _typeColors(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/investments'),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: const Text('Investments'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () => ref.read(investmentProvider.notifier).refresh(),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (investments) {
            final totalInvested = investments.fold(0.0, (s, i) => s + i.investedAmount);
            final totalCurrent = investments.fold(0.0, (s, i) => s + i.currentValue);
            final gainLoss = totalCurrent - totalInvested;
            final gainPct = totalInvested > 0 ? gainLoss / totalInvested * 100 : 0.0;

            final allocationMap = <String, double>{};
            for (final inv in investments) {
              allocationMap[inv.assetType] = (allocationMap[inv.assetType] ?? 0) + inv.currentValue;
            }
            final sections = allocationMap.entries.map((e) => DonutSection(
              label: e.key, value: e.value, color: colors[e.key] ?? c.textTertiary,
            )).toList();

            final grouped = <String, List<InvestmentModel>>{};
            for (final i in investments) grouped.putIfAbsent(i.assetType, () => []).add(i);

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Current Value', value: totalCurrent, accentColor: c.teal)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Gain / Loss', value: gainLoss, accentColor: c.amountColor(gainLoss))),
              ]).animate().fadeIn(),
              const SizedBox(height: 10),
              FSMetricCard(label: 'Total Invested', value: totalInvested, accentColor: c.info,
                  subtitle: '${gainPct.toStringAsFixed(1)}% return').animate(delay: 80.ms).fadeIn(),
              const SizedBox(height: 16),

              if (sections.isNotEmpty) ...[
                Center(child: FSDonutChart(sections: sections, centerLabel: 'Portfolio', centerValue: totalCurrent)).animate(delay: 120.ms).fadeIn(),
                const SizedBox(height: 16),
              ],

              if (investments.isEmpty)
                const FSEmptyState(icon: Icons.pie_chart_rounded, title: 'No investments', subtitle: 'Start tracking your portfolio')
              else
                ...grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[entry.key] ?? c.textTertiary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(entry.key.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
                    ]),
                  ),
                  ...entry.value.map((inv) => _InvestmentCard(
                    inv: inv,
                    color: colors[inv.assetType] ?? c.textTertiary,
                    onDetail: () => _showDetail(context, inv, colors[inv.assetType] ?? c.textTertiary),
                    onDelete: () => _delete(inv.id),
                  )),
                ]),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(context),
        backgroundColor: c.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }

  Future<void> _delete(String id) async => ref.read(investmentProvider.notifier).remove(id);

  void _showDetail(BuildContext context, InvestmentModel inv, Color color) {
    final c = context.fsc;
    final gainColor = c.amountColor(inv.gainLoss);
    final purchaseDate = DateTime.tryParse(inv.purchaseDate);
    showFSBottomSheet(
      context: context,
      title: 'Investment Details',
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _DetailRow(label: 'Name', value: inv.name),
              _DetailRow(label: 'Type', value: inv.assetType.replaceAll('_', ' ').toUpperCase()),
              _DetailRow(label: 'Invested', value: formatINR(inv.investedAmount)),
              _DetailRow(label: 'Current Value', value: formatINR(inv.currentValue), valueColor: color),
              _DetailRow(label: 'Gain / Loss', value: '${inv.gainLoss >= 0 ? '+' : ''}${formatINR(inv.gainLoss)} (${inv.gainLossPct.toStringAsFixed(1)}%)', valueColor: gainColor),
              _DetailRow(label: 'Held For', value: '${inv.daysHeld} days'),
              if (purchaseDate != null) _DetailRow(label: 'Purchase Date', value: '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}'),
              _DetailRow(label: 'Quantity', value: inv.quantity.toStringAsFixed(2)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FSButton(
              label: 'Edit',
              onPressed: () { Navigator.pop(context); _openSheet(context, inv: inv); },
              style: FSButtonStyle.ghost,
            )),
            const SizedBox(width: 8),
            Expanded(child: FSButton(
              label: 'Update Value',
              onPressed: () { Navigator.pop(context); _openUpdateValue(context, inv); },
              style: FSButtonStyle.secondary,
            )),
            const SizedBox(width: 8),
            Expanded(child: FSButton(
              label: 'Delete',
              onPressed: () { Navigator.pop(context); _delete(inv.id); },
              style: FSButtonStyle.danger,
            )),
          ]),
        ]),
      ),
    );
  }

  void _openSheet(BuildContext context, {InvestmentModel? inv}) {
    showFSBottomSheet(context: context, title: inv == null ? 'New Investment' : 'Edit Investment',
        builder: (_) => _AddInvestmentSheet(inv: inv, onSave: (data) async {
          if (inv == null) await ref.read(investmentProvider.notifier).add(data);
          else await ref.read(investmentProvider.notifier).edit(inv.id, data);
        }));
  }

  void _openUpdateValue(BuildContext context, InvestmentModel inv) {
    final ctrl = TextEditingController(text: inv.currentValue.toString());
    showFSBottomSheet(context: context, title: 'Update Value', builder: (_) => Padding(
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

// Add _DetailRow helper
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textSecondary)),
        Flexible(child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? c.textPrimary), textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final InvestmentModel inv;
  final Color color;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  const _InvestmentCard({required this.inv, required this.color, required this.onDetail, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final gainColor = c.amountColor(inv.gainLoss);
    return GestureDetector(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.trending_up_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(inv.name,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (inv.isLtcg) Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(4)),
                child: Text('LTCG', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: c.teal, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Text('${formatINRCompact(inv.investedAmount)} → ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
              Text(formatINRCompact(inv.currentValue), style: GoogleFonts.jetBrainsMono(fontSize: 11, color: c.textPrimary, fontWeight: FontWeight.w500)),
            ]),
            Text('${inv.daysHeld}d held', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
          ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatINRCompact(inv.gainLoss), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: gainColor)),
            Text('${inv.gainLossPct.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: gainColor)),
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
    final c = context.fsc;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Asset Type', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
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
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _purchaseDate, firstDate: DateTime(2000), lastDate: DateTime.now());
            if (d != null) setState(() => _purchaseDate = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: c.textTertiary),
              const SizedBox(width: 8),
              Text('Purchase: ${formatDate(_purchaseDate)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text('Tax Section', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FSChipGroup(options: const ['none','80C','80D','80CCD'], selected: _taxSection, onSelect: (v) => setState(() => _taxSection = v)),
        const SizedBox(height: 16),
        FSButton(label: widget.inv == null ? 'Add Investment' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

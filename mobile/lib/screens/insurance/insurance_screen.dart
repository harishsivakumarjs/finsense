import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/insurance_model.dart';
import '../../providers/insurance_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});
  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Color _dueColor(BuildContext context, int days) {
    final c = context.fsc;
    if (days <= 7) return c.negative;
    if (days <= 30) return c.warning;
    return c.positive;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final async = ref.watch(insuranceProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/insurance'),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: const Text('Insurance'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () => ref.read(insuranceProvider.notifier).refresh(),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (policies) {
            final active = policies.where((p) => p.isActive).toList();
            final totalCoverage = active.fold(0.0, (s, p) => s + p.sumAssured);
            final totalPremium = active.fold(0.0, (s, p) => s + p.annualPremium);
            final total80C = active.where((p) => p.taxSection == '80C').fold(0.0, (s, p) => s + p.taxBenefitAmount);
            final total80D = active.where((p) => p.taxSection == '80D').fold(0.0, (s, p) => s + p.taxBenefitAmount);
            final upcoming = active.where((p) => p.daysUntilDue <= 60 && p.daysUntilDue >= 0).toList()
              ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Total Coverage', value: totalCoverage, accentColor: c.teal)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Annual Premium', value: totalPremium, accentColor: c.warning)),
              ]).animate().fadeIn(),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: FSMetricCard(label: '80C Benefit', value: total80C, accentColor: c.info)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: '80D Benefit', value: total80D, accentColor: c.purple)),
              ]).animate(delay: 80.ms).fadeIn(),
              const SizedBox(height: 16),

              if (upcoming.isNotEmpty) ...[
                Text('UPCOMING RENEWALS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
                const SizedBox(height: 8),
                ...upcoming.map((p) {
                  final dc = _dueColor(context, p.daysUntilDue);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dc.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: dc, width: 3)),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(p.policyName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary))),
                      Text('${p.daysUntilDue}d', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: dc)),
                    ]),
                  );
                }),
                const SizedBox(height: 12),
              ],

              Text('ALL POLICIES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 8),
              if (policies.isEmpty)
                const FSEmptyState(icon: Icons.security_rounded, title: 'No policies', subtitle: 'Add your insurance policies to track them')
              else
                ...policies.map((p) => _PolicyCard(
                  policy: p,
                  dueColor: _dueColor(context, p.daysUntilDue),
                  onTap: () => _showDetail(context, p),
                  onEdit: () => _openSheet(context, policy: p),
                  onDelete: () => _delete(p.id),
                )),
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

  Future<void> _delete(String id) async => ref.read(insuranceProvider.notifier).remove(id);

  void _openSheet(BuildContext context, {InsuranceModel? policy}) {
    showFSBottomSheet(context: context, title: policy == null ? 'Add Policy' : 'Edit Policy',
        builder: (_) => _AddInsuranceSheet(policy: policy, onSave: (data) async {
          if (policy == null) await ref.read(insuranceProvider.notifier).add(data);
          else await ref.read(insuranceProvider.notifier).edit(policy.id, data);
        }));
  }

  void _showDetail(BuildContext context, InsuranceModel p) {
    final c = context.fsc;
    final dc = _dueColor(context, p.daysUntilDue);
    showFSBottomSheet(context: context, title: p.policyName, builder: (_) => Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SUM ASSURED', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 1)),
        Text(formatINR(p.sumAssured), style: GoogleFonts.jetBrainsMono(fontSize: 28, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Annual Premium', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
            Text(formatINR(p.annualPremium), style: GoogleFonts.jetBrainsMono(fontSize: 16, color: c.textPrimary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: dc.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: dc.withAlpha(60))),
            child: Text('Due in ${p.daysUntilDue}d', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: dc)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(6)),
              child: Text('Section ${p.taxSection}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.teal, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Text('Benefit: ${formatINRCompact(p.taxBenefitAmount)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textSecondary)),
        ]),
        if (p.notes != null && p.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(p.notes!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textSecondary)),
        ],
        const SizedBox(height: 16),
        FSButton(label: 'Edit Policy', onPressed: () { Navigator.pop(context); _openSheet(context, policy: p); }, style: FSButtonStyle.ghost, fullWidth: true),
      ]),
    ));
  }
}

class _PolicyCard extends StatelessWidget {
  final InsuranceModel policy;
  final Color dueColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PolicyCard({required this.policy, required this.dueColor, required this.onTap, required this.onEdit, required this.onDelete});

  static const _typeIcons = {
    'health': Icons.favorite_rounded, 'life': Icons.security_rounded,
    'term': Icons.umbrella_rounded, 'vehicle': Icons.directions_car_rounded,
    'home': Icons.home_rounded, 'travel': Icons.flight_rounded,
    'accident': Icons.warning_rounded, 'other': Icons.shield_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final icon = _typeIcons[policy.policyType] ?? Icons.shield_rounded;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: c.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(policy.policyName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
            Text(policy.insurerName, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
            const SizedBox(height: 4),
            Row(children: [
              Text(formatINRCompact(policy.sumAssured), style: GoogleFonts.jetBrainsMono(fontSize: 11, color: c.textPrimary)),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(4)),
                  child: Text(policy.taxSection, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: c.teal, fontWeight: FontWeight.w700))),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatINRCompact(policy.annualPremium), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: dueColor.withAlpha(20), borderRadius: BorderRadius.circular(4)),
              child: Text('${policy.daysUntilDue}d', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: dueColor)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AddInsuranceSheet extends ConsumerStatefulWidget {
  final InsuranceModel? policy;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddInsuranceSheet({this.policy, required this.onSave});
  @override
  ConsumerState<_AddInsuranceSheet> createState() => _AddInsuranceSheetState();
}

class _AddInsuranceSheetState extends ConsumerState<_AddInsuranceSheet> {
  final _policyName = TextEditingController();
  final _insurer = TextEditingController();
  final _policyNo = TextEditingController();
  final _sumAssured = TextEditingController();
  final _premium = TextEditingController();
  final _taxBenefit = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'health';
  String _frequency = 'yearly';
  String _taxSection = '80D';
  DateTime _nextDue = DateTime.now().add(const Duration(days: 365));
  DateTime _startDate = DateTime.now();
  bool _active = true;
  bool _loading = false;

  static const _typeTaxMap = {
    'health': '80D', 'life': '80C', 'term': '80C',
    'vehicle': 'none', 'home': 'none', 'travel': 'none', 'accident': '80D', 'other': 'none',
  };

  @override
  void initState() {
    super.initState();
    if (widget.policy != null) {
      final p = widget.policy!;
      _policyName.text = p.policyName; _insurer.text = p.insurerName;
      _policyNo.text = p.policyNumber ?? ''; _sumAssured.text = p.sumAssured.toString();
      _premium.text = p.annualPremium.toString(); _taxBenefit.text = p.taxBenefitAmount.toString();
      _notes.text = p.notes ?? ''; _type = p.policyType; _frequency = p.premiumFrequency;
      _taxSection = p.taxSection; _active = p.isActive;
      _nextDue = DateTime.tryParse(p.nextDueDate) ?? _nextDue;
      _startDate = DateTime.tryParse(p.startDate) ?? _startDate;
    }
  }

  @override
  void dispose() { _policyName.dispose(); _insurer.dispose(); _policyNo.dispose(); _sumAssured.dispose(); _premium.dispose(); _taxBenefit.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'policy_type': _type, 'policy_name': _policyName.text, 'insurer_name': _insurer.text,
        if (_policyNo.text.isNotEmpty) 'policy_number': _policyNo.text,
        'sum_assured': double.tryParse(_sumAssured.text) ?? 0,
        'annual_premium': double.tryParse(_premium.text) ?? 0,
        'premium_frequency': _frequency,
        'next_due_date': _nextDue.toIso8601String().split('T')[0],
        'start_date': _startDate.toIso8601String().split('T')[0],
        'tax_section': _taxSection,
        'tax_benefit_amount': double.tryParse(_taxBenefit.text) ?? 0,
        'is_active': _active,
        if (_notes.text.isNotEmpty) 'notes': _notes.text,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Type', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FSChipGroup(options: const ['health','life','term','vehicle','home','accident','travel','other'],
            selected: _type, onSelect: (v) => setState(() { _type = v; _taxSection = _typeTaxMap[v] ?? 'none'; })),
        const SizedBox(height: 12),
        FSTextField(label: 'Policy Name', controller: _policyName),
        const SizedBox(height: 10),
        FSTextField(label: 'Insurer', controller: _insurer),
        const SizedBox(height: 10),
        FSTextField(label: 'Policy Number (optional)', controller: _policyNo),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Sum Assured', controller: _sumAssured, isAmount: true)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Annual Premium', controller: _premium, isAmount: true, onChanged: (v) => _taxBenefit.text = v)),
        ]),
        const SizedBox(height: 10),
        Text('Frequency', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FSChipGroup(options: const ['monthly','quarterly','half_yearly','yearly'], selected: _frequency, onSelect: (v) => setState(() => _frequency = v)),
        const SizedBox(height: 10),
        Text('Tax Section', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FSChipGroup(options: const ['80C','80D','none'], selected: _taxSection, onSelect: (v) => setState(() => _taxSection = v)),
        const SizedBox(height: 10),
        FSTextField(label: 'Tax Benefit Amount', controller: _taxBenefit, isAmount: true),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _nextDue, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
            if (d != null) setState(() => _nextDue = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: c.textTertiary),
              const SizedBox(width: 8),
              Text('Next Due: ${formatDate(_nextDue)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: Text('Active', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary)),
          value: _active, onChanged: (v) => setState(() => _active = v),
          dense: true, contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        FSButton(label: widget.policy == null ? 'Add Policy' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

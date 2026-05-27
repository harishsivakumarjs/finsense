import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class DebtScreen extends ConsumerStatefulWidget {
  const DebtScreen({super.key});
  @override
  ConsumerState<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends ConsumerState<DebtScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final loansAsync = ref.watch(loanProvider);
    final cardsAsync = ref.watch(cardProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/debt'),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: const Text('Debt Manager'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () async {
          await ref.read(loanProvider.notifier).refresh();
          await ref.read(cardProvider.notifier).refresh();
        },
        child: loansAsync.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (loans) => cardsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cards) => _buildBody(context, loans, cards),
          ),
        ),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildBody(BuildContext context, List<LoanModel> loans, List<CreditCardModel> cards) {
    final c = context.fsc;
    final totalEmi = loans.where((l) => l.isActive).fold(0.0, (s, l) => s + l.emiAmount);
    final totalOutstanding = loans.fold(0.0, (s, l) => s + l.principal);
    final ccMinDue = cards.fold(0.0, (s, cc) => s + cc.minimumDue);

    // Get income from dashboard for score calculation
    final dashAsync = ref.watch(dashboardProvider);
    final income = dashAsync.value?.totalIncome ?? 0.0;
    final savings = dashAsync.value != null
        ? (dashAsync.value!.totalIncome - dashAsync.value!.totalExpenses)
        : 0.0;

    final dti = income > 0 ? (totalEmi + ccMinDue) / income : 0.0;
    final dangerScore = _calcDangerScore(income, totalEmi, ccMinDue, savings);

    Color scoreColor(int s) {
      if (s < 30) return c.positive;
      if (s < 60) return c.warning;
      return c.negative;
    }

    final sc = scoreColor(dangerScore);
    final scoreLabel = dangerScore < 30 ? 'Safe' : dangerScore < 60 ? 'Moderate Risk' : 'High Risk';

    final forecastData = List.generate(6, (i) {
      final m = i + 1;
      final projIncome = income * (1 + 0.005 * m);
      final dtiVal = projIncome > 0 ? (totalEmi / projIncome * 100) : 0.0;
      return {'month': 'M+$m', 'dti': dtiVal};
    });

    Color dtiColor(double v) {
      if (v < 20) return c.positive;
      if (v < 40) return c.info;
      if (v < 70) return c.warning;
      return c.negative;
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
      // Summary card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MONTHLY EMI BURDEN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(formatINR(totalEmi), style: GoogleFonts.jetBrainsMono(fontSize: 28, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 4),
          Text('Total principal: ${formatINRCompact(totalOutstanding)}  ·  DTI: ${(dti * 100).toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
        ]),
      ).animate().fadeIn(),
      const SizedBox(height: 16),

      // Debt Danger Score
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sc.withAlpha(40)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.shield_outlined, size: 14, color: sc),
            const SizedBox(width: 6),
            Text('DEBT DANGER SCORE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: sc.withAlpha(20), borderRadius: BorderRadius.circular(20)),
              child: Text(scoreLabel, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: sc)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text('$dangerScore', style: GoogleFonts.jetBrainsMono(fontSize: 26, fontWeight: FontWeight.w700, color: sc)),
            Text('/100', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textTertiary)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: dangerScore / 100, backgroundColor: c.surface, color: sc, minHeight: 10),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Safe', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.positive)),
            Text('Moderate', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.warning)),
            Text('Danger', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.negative)),
          ]),
        ]),
      ).animate(delay: 80.ms).fadeIn(),
      const SizedBox(height: 20),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('LOANS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
        TextButton.icon(
          onPressed: () => _openLoanSheet(context),
          icon: Icon(Icons.add_rounded, size: 14, color: c.teal),
          label: Text('Add Loan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: c.teal),
        ),
      ]),
      if (loans.isEmpty)
        const FSEmptyState(icon: Icons.credit_card_off_rounded, title: 'No loans', subtitle: 'Add a loan to track your EMIs')
      else
        ...loans.map((l) => _LoanCard(loan: l, onDetail: () => _showLoanDetail(context, l), onDelete: () => _deleteLoan(l.id))),

      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('CREDIT CARDS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
        TextButton.icon(
          onPressed: () => _openCardSheet(context),
          icon: Icon(Icons.add_rounded, size: 14, color: c.teal),
          label: Text('Add Card', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: c.teal),
        ),
      ]),
      if (cards.isEmpty)
        const FSEmptyState(icon: Icons.credit_card_off_rounded, title: 'No credit cards', subtitle: 'Add a card to track utilisation')
      else
        ...cards.map((cc) => _CardWidget(card: cc, onDetail: () => _showCardDetail(context, cc), onDelete: () => _deleteCard(cc.id))),

      // 6-month DTI forecast
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('6-MONTH DTI FORECAST', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Assuming 0.5% monthly income growth', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
          const SizedBox(height: 12),
          FSBarChart(data: forecastData, xKey: 'month', yKey: 'dti', colorFn: dtiColor, height: 140),
        ]),
      ).animate(delay: 200.ms).fadeIn(),

      const SizedBox(height: 80),
    ]);
  }

  int _calcDangerScore(double income, double totalEmi, double ccMin, double savings) {
    final totalDebt = totalEmi + ccMin;
    // No income recorded but have debts → inherently high risk
    if (income <= 0) return totalDebt > 0 ? 75 : 0;

    final dti = totalDebt / income;
    double score = 0;
    if (dti >= 0.7) score += 60;
    else if (dti >= 0.5) score += 45;
    else if (dti >= 0.4) score += 30;
    else if (dti >= 0.3) score += 15;
    else score += dti * 50;

    final savingsRate = income > 0 ? savings / income : 0;
    if (savingsRate < 0.05) score += 15;
    else if (savingsRate < 0.1) score += 10;
    else if (savingsRate < 0.2) score += 5;

    if (ccMin > 0) score += (ccMin / income * 30).clamp(0, 15);
    return score.round().clamp(0, 100);
  }

  void _showLoanDetail(BuildContext context, LoanModel loan) {
    final c = context.fsc;
    showFSBottomSheet(
      context: context,
      title: 'Loan Details',
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _DetailRow(label: 'Loan Name', value: loan.loanName),
              _DetailRow(label: 'Lender', value: loan.bankName),
              _DetailRow(label: 'Type', value: loan.loanType.toUpperCase()),
              _DetailRow(label: 'Principal', value: formatINR(loan.principal)),
              _DetailRow(label: 'EMI / month', value: formatINR(loan.emiAmount), valueColor: c.negative),
              _DetailRow(label: 'Interest Rate', value: '${loan.interestRate}%'),
              _DetailRow(label: 'Tenure', value: '${loan.monthsTotal} months'),
              _DetailRow(label: 'Status', value: loan.isActive ? 'Active' : 'Closed', valueColor: loan.isActive ? c.positive : c.textTertiary),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FSButton(
              label: 'Edit',
              onPressed: () { Navigator.pop(context); _openLoanSheet(context, loan: loan); },
              style: FSButtonStyle.ghost,
            )),
            const SizedBox(width: 12),
            Expanded(child: FSButton(
              label: 'Delete',
              onPressed: () { Navigator.pop(context); _deleteLoan(loan.id); },
              style: FSButtonStyle.danger,
            )),
          ]),
        ]),
      ),
    );
  }

  void _showCardDetail(BuildContext context, CreditCardModel card) {
    final c = context.fsc;
    final util = card.utilisation;
    final utilColor = util > 0.7 ? c.negative : util > 0.3 ? c.warning : c.positive;
    showFSBottomSheet(
      context: context,
      title: 'Card Details',
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _DetailRow(label: 'Card Name', value: card.cardName),
              _DetailRow(label: 'Bank', value: card.bankName),
              _DetailRow(label: 'Credit Limit', value: formatINR(card.creditLimit)),
              _DetailRow(label: 'Outstanding', value: formatINR(card.outstanding), valueColor: card.outstanding > 0 ? c.negative : c.positive),
              _DetailRow(label: 'Min Due', value: formatINR(card.minimumDue)),
              _DetailRow(label: 'Utilization', value: '${(util * 100).toStringAsFixed(0)}%', valueColor: utilColor),
              if (card.dueDate != null) _DetailRow(label: 'Due Date', value: '${card.dueDate}th of month'),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FSButton(
              label: 'Edit',
              onPressed: () { Navigator.pop(context); _openCardSheet(context, card: card); },
              style: FSButtonStyle.ghost,
            )),
            const SizedBox(width: 12),
            Expanded(child: FSButton(
              label: 'Delete',
              onPressed: () { Navigator.pop(context); _deleteCard(card.id); },
              style: FSButtonStyle.danger,
            )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _deleteLoan(String id) async {
    await ref.read(loanProvider.notifier).remove(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan deleted')));
  }

  Future<void> _deleteCard(String id) async {
    await ref.read(cardProvider.notifier).remove(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card deleted')));
  }

  void _openLoanSheet(BuildContext context, {LoanModel? loan}) {
    showFSBottomSheet(context: context, title: loan == null ? 'Add Loan' : 'Edit Loan',
        builder: (_) => _AddLoanSheet(loan: loan, onSave: (data) async {
          if (loan == null) await ref.read(loanProvider.notifier).add(data);
          else await ref.read(loanProvider.notifier).edit(loan.id, data);
        }));
  }

  void _openCardSheet(BuildContext context, {CreditCardModel? card}) {
    showFSBottomSheet(context: context, title: card == null ? 'Add Credit Card' : 'Edit Card',
        builder: (_) => _AddCardSheet(card: card, onSave: (data) async {
          if (card == null) await ref.read(cardProvider.notifier).add(data);
          else await ref.read(cardProvider.notifier).edit(card.id, data);
        }));
  }
}

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

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  const _LoanCard({required this.loan, required this.onDetail, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return GestureDetector(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loan.loanName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
              Text(loan.bankName, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatINR(loan.emiAmount), style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
              Text('/month', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
            ]),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Principal: ${formatINRCompact(loan.principal)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
            Text('${loan.monthsTotal} months', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.infoDim, borderRadius: BorderRadius.circular(4)),
              child: Text('${loan.interestRate}%', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.info, fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final CreditCardModel card;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  const _CardWidget({required this.card, required this.onDetail, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final util = card.utilisation;
    final utilColor = util > 0.7 ? c.negative : util > 0.3 ? c.warning : c.positive;
    return GestureDetector(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.cardName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
            Text(card.bankName, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
            const SizedBox(height: 8),
            Text('Outstanding: ${formatINR(card.outstanding)}',
                style: GoogleFonts.jetBrainsMono(fontSize: 12, color: card.outstanding > 0 ? c.negative : c.positive, fontWeight: FontWeight.w500)),
            Text('Min due: ${formatINR(card.minimumDue)}${card.dueDate != null ? ' · Due ${card.dueDate}th' : ''}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
          ])),
          const SizedBox(width: 16),
          Column(children: [
            SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(value: util, strokeWidth: 5, backgroundColor: c.surface, color: utilColor),
            ),
            const SizedBox(height: 4),
            Text('${(util * 100).toStringAsFixed(0)}%', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: utilColor, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

class _AddLoanSheet extends ConsumerStatefulWidget {
  final LoanModel? loan;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddLoanSheet({this.loan, required this.onSave});
  @override
  ConsumerState<_AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends ConsumerState<_AddLoanSheet> {
  final _loanName = TextEditingController();
  final _bank = TextEditingController();
  final _principal = TextEditingController();
  final _emi = TextEditingController();
  final _rate = TextEditingController();
  final _months = TextEditingController();
  String _type = 'personal';
  bool _active = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      final l = widget.loan!;
      _loanName.text = l.loanName; _bank.text = l.bankName;
      _principal.text = l.principal.toString(); _emi.text = l.emiAmount.toString();
      _rate.text = l.interestRate.toString(); _months.text = l.monthsTotal.toString();
      _type = l.loanType; _active = l.isActive;
    }
  }

  @override
  void dispose() { _loanName.dispose(); _bank.dispose(); _principal.dispose(); _emi.dispose(); _rate.dispose(); _months.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'loan_type': _type, 'loan_name': _loanName.text, 'bank_name': _bank.text,
        'principal': double.tryParse(_principal.text) ?? 0,
        'emi_amount': double.tryParse(_emi.text) ?? 0,
        'interest_rate': double.tryParse(_rate.text) ?? 0,
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'months_total': int.tryParse(_months.text) ?? 0,
        'is_active': _active,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan saved'))); }
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
        FSChipGroup(options: const ['home','personal','car','education','bnpl','other'], selected: _type, onSelect: (v) => setState(() => _type = v)),
        const SizedBox(height: 12),
        FSTextField(label: 'Loan Name', controller: _loanName),
        const SizedBox(height: 10),
        FSTextField(label: 'Bank Name', controller: _bank),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Principal', controller: _principal, isAmount: true)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'EMI / month', controller: _emi, isAmount: true)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Interest %', controller: _rate, keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Total Months', controller: _months, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        SwitchListTile(title: Text('Active', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary)), value: _active, onChanged: (v) => setState(() => _active = v), dense: true, contentPadding: EdgeInsets.zero),
        const SizedBox(height: 16),
        FSButton(label: widget.loan == null ? 'Add Loan' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _AddCardSheet extends ConsumerStatefulWidget {
  final CreditCardModel? card;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddCardSheet({this.card, required this.onSave});
  @override
  ConsumerState<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<_AddCardSheet> {
  final _name = TextEditingController();
  final _bank = TextEditingController();
  final _limit = TextEditingController();
  final _outstanding = TextEditingController();
  final _minDue = TextEditingController();
  final _dueDate = TextEditingController();
  final _stmtDate = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      final cc = widget.card!;
      _name.text = cc.cardName; _bank.text = cc.bankName;
      _limit.text = cc.creditLimit.toString(); _outstanding.text = cc.outstanding.toString();
      _minDue.text = cc.minimumDue.toString(); _dueDate.text = cc.dueDate?.toString() ?? ''; _stmtDate.text = cc.statementDate?.toString() ?? '';
    }
  }

  @override
  void dispose() { _name.dispose(); _bank.dispose(); _limit.dispose(); _outstanding.dispose(); _minDue.dispose(); _dueDate.dispose(); _stmtDate.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'card_name': _name.text, 'bank_name': _bank.text,
        'credit_limit': double.tryParse(_limit.text) ?? 0,
        'outstanding': double.tryParse(_outstanding.text) ?? 0,
        'minimum_due': double.tryParse(_minDue.text) ?? 0,
        'due_date': int.tryParse(_dueDate.text) ?? 1,
        'statement_date': int.tryParse(_stmtDate.text) ?? 1,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSTextField(label: 'Card Name', controller: _name),
        const SizedBox(height: 10),
        FSTextField(label: 'Bank Name', controller: _bank),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Credit Limit', controller: _limit, isAmount: true)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Outstanding', controller: _outstanding, isAmount: true)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Minimum Due', controller: _minDue, isAmount: true)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Due Date (day)', controller: _dueDate, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        FSTextField(label: 'Statement Date (day)', controller: _stmtDate, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        FSButton(label: widget.card == null ? 'Add Card' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

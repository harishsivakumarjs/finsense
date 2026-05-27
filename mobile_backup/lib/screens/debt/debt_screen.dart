import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/common/fs_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class DebtScreen extends ConsumerStatefulWidget {
  const DebtScreen({super.key});
  @override
  ConsumerState<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends ConsumerState<DebtScreen> {
  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loanProvider);
    final cardsAsync = ref.watch(cardProvider);

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: const Text('Debt Manager')),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () async {
          await ref.read(loanProvider.notifier).refresh();
          await ref.read(cardProvider.notifier).refresh();
        },
        child: loansAsync.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList()]),
          error: (e, _) => Center(child: Text('Error: $e')),
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
    final totalEmi = loans.where((l) => l.isActive).fold(0.0, (s, l) => s + l.emiAmount);
    final totalOutstanding = loans.fold(0.0, (s, l) => s + l.outstandingBalance);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Score card
      FSCard(
        accentTop: totalEmi > 0 ? FSColors.warning : FSColors.positive,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MONTHLY EMI BURDEN', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(formatINR(totalEmi), style: GoogleFonts.jetBrainsMono(fontSize: 26, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
          Text('Total outstanding: ${formatINRCompact(totalOutstanding)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textTertiary)),
        ]),
      ).animate().fadeIn(),
      const SizedBox(height: 16),

      // Loans section
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('LOANS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
        TextButton.icon(
          onPressed: () => _openLoanSheet(context),
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Add Loan'),
          style: TextButton.styleFrom(foregroundColor: FSColors.teal),
        ),
      ]),
      if (loans.isEmpty)
        const FSEmptyState(icon: Icons.credit_card_off_rounded, title: 'No loans', subtitle: 'Add a loan to track your EMIs')
      else
        ...loans.map((l) => _LoanCard(loan: l, onEdit: () => _openLoanSheet(context, loan: l), onDelete: () => _deleteLoan(l.id))),

      const SizedBox(height: 16),

      // Credit Cards section
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('CREDIT CARDS', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
        TextButton.icon(
          onPressed: () => _openCardSheet(context),
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Add Card'),
          style: TextButton.styleFrom(foregroundColor: FSColors.teal),
        ),
      ]),
      if (cards.isEmpty)
        const FSEmptyState(icon: Icons.credit_card_off_rounded, title: 'No credit cards', subtitle: 'Add a card to track utilisation')
      else
        ...cards.map((c) => _CardWidget(card: c, onEdit: () => _openCardSheet(context, card: c), onDelete: () => _deleteCard(c.id))),

      const SizedBox(height: 80),
    ]);
  }

  Future<void> _deleteLoan(int id) async {
    await ref.read(loanProvider.notifier).remove(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan deleted')));
  }

  Future<void> _deleteCard(int id) async {
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

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _LoanCard({required this.loan, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: FSColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loan.loanName, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: FSColors.textPrimary)),
              Text(loan.bankName, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textTertiary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatINR(loan.emiAmount), style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
              Text('/month', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
            ]),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: loan.progressFraction, backgroundColor: FSColors.tertiary, color: FSColors.teal, minHeight: 5),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${loan.monthsPaid}/${loan.totalMonths} months', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
            Text('Outstanding: ${formatINRCompact(loan.outstandingBalance)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: FSColors.infoDim, borderRadius: BorderRadius.circular(4)),
                child: Text('${loan.interestRate}%', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.info, fontWeight: FontWeight.w600))),
          ]),
        ]),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final CreditCardModel card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CardWidget({required this.card, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final util = card.utilisation;
    final utilColor = util > 0.7 ? FSColors.negative : util > 0.3 ? FSColors.warning : FSColors.positive;
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: FSColors.border)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.cardName, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: FSColors.textPrimary)),
            Text(card.bankName, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textTertiary)),
            const SizedBox(height: 8),
            Text('Outstanding: ${formatINR(card.outstanding)}', style: GoogleFonts.jetBrainsMono(fontSize: 13, color: card.outstanding > 0 ? FSColors.negative : FSColors.positive, fontWeight: FontWeight.w500)),
            Text('Min due: ${formatINR(card.minimumDue)} · Due on ${card.dueDate}th', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
          ])),
          const SizedBox(width: 12),
          Column(children: [
            SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(value: util, strokeWidth: 5, backgroundColor: FSColors.tertiary, color: utilColor),
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
  DateTime _startDate = DateTime.now();
  bool _active = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      final l = widget.loan!;
      _loanName.text = l.loanName; _bank.text = l.bankName;
      _principal.text = l.principalAmount.toString(); _emi.text = l.emiAmount.toString();
      _rate.text = l.interestRate.toString(); _months.text = l.totalMonths.toString();
      _type = l.loanType; _active = l.isActive;
      _startDate = DateTime.tryParse(l.startDate) ?? DateTime.now();
    }
  }

  @override
  void dispose() { _loanName.dispose(); _bank.dispose(); _principal.dispose(); _emi.dispose(); _rate.dispose(); _months.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'loan_type': _type, 'loan_name': _loanName.text, 'bank_name': _bank.text,
        'principal_amount': double.tryParse(_principal.text) ?? 0,
        'emi_amount': double.tryParse(_emi.text) ?? 0,
        'interest_rate': double.tryParse(_rate.text) ?? 0,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'total_months': int.tryParse(_months.text) ?? 0,
        'is_active': _active,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSChipGroup(options: ['home','personal','car','education','bnpl','other'], selected: _type, onSelect: (v) => setState(() => _type = v)),
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
          Expanded(child: FSTextField(label: 'Interest Rate %', controller: _rate, keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Total Months', controller: _months, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        SwitchListTile(title: Text('Active', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary)), value: _active, onChanged: (v) => setState(() => _active = v), dense: true, contentPadding: EdgeInsets.zero),
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
      final c = widget.card!;
      _name.text = c.cardName; _bank.text = c.bankName;
      _limit.text = c.creditLimit.toString(); _outstanding.text = c.outstanding.toString();
      _minDue.text = c.minimumDue.toString(); _dueDate.text = c.dueDate.toString(); _stmtDate.text = c.statementDate.toString();
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

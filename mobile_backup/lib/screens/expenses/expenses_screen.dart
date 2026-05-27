import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(expenseProvider);
    final budget = 50000.0;

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth,
              dropdownColor: FSColors.card,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary),
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1,
                  child: Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i]))),
              onChanged: (m) { setState(() => _selectedMonth = m!); ref.read(expenseProvider.notifier).refresh(month: m); },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () => ref.read(expenseProvider.notifier).refresh(month: _selectedMonth),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [
            const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: FSColors.negative))),
          data: (items) {
            final total = items.fold(0.0, (s, e) => s + e.amount);
            final remaining = budget - total;
            final grouped = _groupByDate(items);

            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Spent', value: total, accentColor: FSColors.negative)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Remaining', value: remaining, accentColor: remaining >= 0 ? FSColors.positive : FSColors.negative)),
              ]).animate().fadeIn(),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const FSEmptyState(icon: Icons.receipt_long_rounded, title: 'No expenses', subtitle: 'Tap + to record an expense')
              else
                ...grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(entry.key, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: FSColors.textTertiary)),
                  ),
                  ...entry.value.map((e) => _ExpenseRow(entry: e,
                      onEdit: () => _openSheet(context, entry: e),
                      onDelete: () => _delete(e.id))),
                ]),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 1),
    );
  }

  Map<String, List<ExpenseModel>> _groupByDate(List<ExpenseModel> items) {
    final grouped = <String, List<ExpenseModel>>{};
    for (final e in items) {
      final d = DateTime.tryParse(e.date);
      final key = d != null ? formatDate(d) : e.date;
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: FSColors.card,
      title: Text('Delete expense?', style: GoogleFonts.plusJakartaSans(color: FSColors.textPrimary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: FSColors.negative))),
      ],
    ));
    if (ok == true) await ref.read(expenseProvider.notifier).remove(id);
  }

  void _openSheet(BuildContext context, {ExpenseModel? entry}) {
    showFSBottomSheet(context: context, title: entry == null ? 'Add Expense' : 'Edit Expense',
        builder: (_) => AddExpenseSheet(entry: entry, onSave: (data) async {
          if (entry == null) await ref.read(expenseProvider.notifier).add(data);
          else await ref.read(expenseProvider.notifier).edit(entry.id, data);
        }));
  }
}

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExpenseRow({required this.entry, required this.onEdit, required this.onDelete});

  static const _catIcons = {
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'bills': Icons.receipt_rounded,
    'health': Icons.favorite_rounded,
    'entertainment': Icons.movie_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'education': Icons.school_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _catIcons[entry.category] ?? Icons.circle_rounded;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: FSColors.redDim,
        child: const Icon(Icons.delete_rounded, color: FSColors.negative),
      ),
      confirmDismiss: (_) async { onDelete(); return false; },
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: FSColors.border)),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: FSColors.redDim, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: FSColors.negative)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.description, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: FSColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: FSColors.redDim, borderRadius: BorderRadius.circular(4)),
                    child: Text(expenseCategoryLabels[entry.category] ?? entry.category, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.negative, fontWeight: FontWeight.w600))),
                if (entry.isRecurring) ...[const SizedBox(width: 4), const Icon(Icons.repeat_rounded, size: 11, color: FSColors.info)],
              ]),
            ])),
            Text(formatINR(entry.amount), style: GoogleFonts.jetBrainsMono(fontSize: 13, color: FSColors.negative, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class AddExpenseSheet extends ConsumerStatefulWidget {
  final ExpenseModel? entry;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const AddExpenseSheet({super.key, this.entry, required this.onSave});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _category = 'food';
  DateTime _date = DateTime.now();
  bool _recurring = false;
  bool _creator = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _amount.text = widget.entry!.amount.toString();
      _desc.text = widget.entry!.description;
      _category = widget.entry!.category;
      _date = DateTime.tryParse(widget.entry!.date) ?? DateTime.now();
      _recurring = widget.entry!.isRecurring;
      _creator = widget.entry!.isCreatorExpense;
    }
  }

  @override
  void dispose() { _amount.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_amount.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'amount': double.parse(_amount.text),
        'category': _category,
        'description': _desc.text.isEmpty ? _category : _desc.text,
        'date': _date.toIso8601String().split('T')[0],
        'is_recurring': _recurring,
        'is_creator_expense': _creator,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.entry == null ? 'Expense added' : 'Expense updated'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSTextField(label: 'Amount', controller: _amount, isAmount: true),
        const SizedBox(height: 12),
        FSTextField(label: 'Description', controller: _desc),
        const SizedBox(height: 12),
        Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
        const SizedBox(height: 8),
        FSChipGroup(options: expenseCategoryLabels.keys.toList(), selected: _category, onSelect: (v) => setState(() => _category = v)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10), border: Border.all(color: FSColors.border)),
            child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 16, color: FSColors.textTertiary), const SizedBox(width: 8),
              Text(formatDate(_date), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FSColors.textPrimary))]),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: SwitchListTile(title: Text('Recurring', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary)), value: _recurring, onChanged: (v) => setState(() => _recurring = v), dense: true, contentPadding: EdgeInsets.zero)),
          Expanded(child: SwitchListTile(title: Text('Creator expense', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary)), value: _creator, onChanged: (v) => setState(() => _creator = v), dense: true, contentPadding: EdgeInsets.zero)),
        ]),
        const SizedBox(height: 16),
        FSButton(label: widget.entry == null ? 'Add Expense' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

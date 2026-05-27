import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
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
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseProvider.notifier).refresh(month: _selectedMonth, year: _selectedYear);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final async = ref.watch(expenseProvider);
    const budget = 50000.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/expenses'),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Expenses'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () => ref.read(expenseProvider.notifier).refresh(month: _selectedMonth, year: _selectedYear),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (items) {
            final total = items.fold(0.0, (s, e) => s + e.amount);
            final remaining = budget - total;
            final grouped = _groupByDate(items);

            // Category spending for bar chart
            final byCategory = <String, double>{};
            for (final e in items) {
              byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
            }
            final chartData = byCategory.entries
                .map((e) => {'cat': (expenseCategoryLabels[e.key] ?? e.key).substring(0, 3).toUpperCase(), 'amount': e.value})
                .toList();

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Spent', value: total, accentColor: c.negative)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Remaining', value: remaining, accentColor: remaining >= 0 ? c.positive : c.negative)),
              ]).animate().fadeIn(),
              const SizedBox(height: 16),

              // Month / Year calendar picker
              GestureDetector(
                onTap: () => _pickMonthYear(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: c.teal),
                    const SizedBox(width: 10),
                    Text(
                      '${_months[_selectedMonth - 1]} $_selectedYear',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more_rounded, size: 16, color: c.textTertiary),
                  ]),
                ),
              ).animate(delay: 50.ms).fadeIn(),
              const SizedBox(height: 16),

              // Budget progress
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('BUDGET USAGE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
                    Text('${((total / budget) * 100).toStringAsFixed(0)}%', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: total > budget ? c.negative : c.positive, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (total / budget).clamp(0.0, 1.0),
                      backgroundColor: c.surface,
                      color: total > budget * 0.8 ? c.negative : total > budget * 0.6 ? c.warning : c.positive,
                      minHeight: 8,
                    ),
                  ),
                ]),
              ).animate(delay: 50.ms).fadeIn(),
              const SizedBox(height: 16),

              // Spending by category bar chart
              if (chartData.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SPENDING BY CATEGORY', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    FSBarChart(data: chartData, xKey: 'cat', yKey: 'amount', defaultColor: c.negative, height: 160),
                  ]),
                ).animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: 16),
              ],

              if (items.isEmpty)
                const FSEmptyState(icon: Icons.receipt_long_rounded, title: 'No expenses', subtitle: 'Tap + to record an expense')
              else
                ...grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(entry.key, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.5)),
                  ),
                  ...entry.value.asMap().entries.map((e) => _ExpenseRow(
                    entry: e.value,
                    index: e.key,
                    onDetail: () => _showDetail(context, e.value),
                    onDelete: () => _delete(e.value.id),
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
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 1),
    );
  }

  Map<String, List<ExpenseModel>> _groupByDate(List<ExpenseModel> items) {
    final grouped = <String, List<ExpenseModel>>{};
    for (final e in items) {
      final d = DateTime.tryParse(e.spentOn);
      final key = d != null ? formatDate(d) : e.spentOn;
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  Future<void> _pickMonthYear(BuildContext context) async {
    final c = context.fsc;
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    final result = await showDialog<(int, int)?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: c.card,
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          title: Row(children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: c.textSecondary),
              onPressed: () => setSt(() => tempYear--),
            ),
            Expanded(child: Text(
              '$tempYear',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
            )),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: c.textSecondary),
              onPressed: () => setSt(() { if (tempYear < DateTime.now().year) tempYear++; }),
            ),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2),
              itemCount: 12,
              itemBuilder: (_, i) {
                final isSelected = tempMonth == i + 1;
                final isFuture = DateTime(tempYear, i + 1).isAfter(DateTime.now());
                return GestureDetector(
                  onTap: isFuture ? null : () => setSt(() => tempMonth = i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? c.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? c.teal : c.border),
                    ),
                    child: Center(child: Text(
                      _months[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isFuture ? c.textTertiary : (isSelected ? Colors.white : c.textPrimary),
                      ),
                    )),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: c.textSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, (tempMonth, tempYear)), child: Text('OK', style: TextStyle(color: c.teal, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() { _selectedMonth = result.$1; _selectedYear = result.$2; });
      ref.read(expenseProvider.notifier).refresh(month: _selectedMonth, year: _selectedYear);
    }
  }

  void _showDetail(BuildContext context, ExpenseModel entry) {
    final c = context.fsc;
    final date = DateTime.tryParse(entry.spentOn);
    showFSBottomSheet(
      context: context,
      title: 'Expense Details',
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _DetailRow(label: 'Description', value: entry.description),
              _DetailRow(label: 'Category', value: expenseCategoryLabels[entry.category] ?? entry.category),
              _DetailRow(label: 'Amount', value: formatINR(entry.amount), valueColor: c.negative),
              if (date != null) _DetailRow(label: 'Date', value: formatDate(date)),
              _DetailRow(label: 'Recurring', value: entry.isRecurring ? 'Yes' : 'No'),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FSButton(
              label: 'Edit',
              onPressed: () { Navigator.pop(context); _openSheet(context, entry: entry); },
              style: FSButtonStyle.ghost,
            )),
            const SizedBox(width: 12),
            Expanded(child: FSButton(
              label: 'Delete',
              onPressed: () { Navigator.pop(context); _delete(entry.id); },
              style: FSButtonStyle.danger,
            )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final c = context.fsc;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Delete expense?', style: GoogleFonts.plusJakartaSans(color: c.textPrimary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: c.negative))),
      ],
    ));
    if (ok == true && mounted) await ref.read(expenseProvider.notifier).remove(id);
  }

  void _openSheet(BuildContext context, {ExpenseModel? entry}) {
    showFSBottomSheet(context: context, title: entry == null ? 'Add Expense' : 'Edit Expense',
        builder: (_) => AddExpenseSheet(entry: entry, onSave: (data) async {
          if (entry == null) await ref.read(expenseProvider.notifier).add(data);
          else await ref.read(expenseProvider.notifier).edit(entry.id, data);
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

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel entry;
  final int index;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  const _ExpenseRow({required this.entry, required this.index, required this.onDetail, required this.onDelete});

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
    final c = context.fsc;
    final icon = _catIcons[entry.category] ?? Icons.circle_rounded;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: c.redDim,
        child: Icon(Icons.delete_rounded, color: c.negative),
      ),
      confirmDismiss: (_) async { onDelete(); return false; },
      child: GestureDetector(
        onTap: onDetail,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: c.redDim, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: c.negative),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.description,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c.redDim, borderRadius: BorderRadius.circular(4)),
                  child: Text(expenseCategoryLabels[entry.category] ?? entry.category,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.negative, fontWeight: FontWeight.w600)),
                ),
                if (entry.isRecurring) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.repeat_rounded, size: 11, color: c.info),
                ],
              ]),
            ])),
            Text(formatINR(entry.amount), style: GoogleFonts.jetBrainsMono(fontSize: 13, color: c.negative, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30));
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
      _date = DateTime.tryParse(widget.entry!.spentOn) ?? DateTime.now();
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
        'spent_on': _date.toIso8601String().split('T')[0],
        'is_recurring': _recurring,
        'is_creator_expense': _creator,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.entry == null ? 'Expense added' : 'Expense updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSTextField(label: 'Amount', controller: _amount, isAmount: true),
        const SizedBox(height: 12),
        FSTextField(label: 'Description', controller: _desc),
        const SizedBox(height: 12),
        Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FSChipGroup(options: expenseCategoryLabels.keys.toList(), selected: _category, onSelect: (v) => setState(() => _category = v), labelMap: expenseCategoryLabels),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: c.textTertiary),
              const SizedBox(width: 8),
              Text(formatDate(_date), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.textPrimary)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: SwitchListTile(
            title: Text('Recurring', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary)),
            value: _recurring, onChanged: (v) => setState(() => _recurring = v),
            dense: true, contentPadding: EdgeInsets.zero,
          )),
          Expanded(child: SwitchListTile(
            title: Text('Creator', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary)),
            value: _creator, onChanged: (v) => setState(() => _creator = v),
            dense: true, contentPadding: EdgeInsets.zero,
          )),
        ]),
        const SizedBox(height: 16),
        FSButton(label: widget.entry == null ? 'Add Expense' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

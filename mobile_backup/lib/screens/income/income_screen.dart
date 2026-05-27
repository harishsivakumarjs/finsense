import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/income_model.dart';
import '../../providers/income_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  String _search = '';
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(incomeProvider);

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth,
              dropdownColor: FSColors.card,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i]),
              )),
              onChanged: (m) {
                setState(() => _selectedMonth = m!);
                ref.read(incomeProvider.notifier).refresh(month: m);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () => ref.read(incomeProvider.notifier).refresh(month: _selectedMonth),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [
            const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: FSColors.negative))),
          data: (items) {
            final filtered = _search.isEmpty ? items : items.where((i) => i.description.toLowerCase().contains(_search.toLowerCase())).toList();
            final total = filtered.fold(0.0, (s, e) => s + e.amount);

            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Total Income', value: total, accentColor: FSColors.positive)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Entries', value: filtered.length.toDouble(),
                    accentColor: FSColors.teal, isAmount: false)),
              ]).animate().fadeIn(),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search income...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, color: FSColors.textTertiary, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const FSEmptyState(icon: Icons.account_balance_wallet_rounded, title: 'No income recorded', subtitle: 'Tap + to add your first income entry')
              else
                ...filtered.map((e) => _IncomeRow(entry: e, onEdit: () => _openSheet(context, entry: e), onDelete: () => _delete(e.id))),
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

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: FSColors.card,
      title: Text('Delete entry?', style: GoogleFonts.plusJakartaSans(color: FSColors.textPrimary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: FSColors.negative))),
      ],
    ));
    if (ok == true) {
      await ref.read(incomeProvider.notifier).remove(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
    }
  }

  void _openSheet(BuildContext context, {IncomeModel? entry}) {
    showFSBottomSheet(context: context, title: entry == null ? 'Add Income' : 'Edit Income',
        builder: (_) => AddIncomeSheet(entry: entry, onSave: (data) async {
          if (entry == null) {
            await ref.read(incomeProvider.notifier).add(data);
          } else {
            await ref.read(incomeProvider.notifier).edit(entry.id, data);
          }
        }));
  }
}

class _IncomeRow extends StatelessWidget {
  final IncomeModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _IncomeRow({required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(entry.date);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: FSColors.redDim,
        child: const Icon(Icons.delete_rounded, color: FSColors.negative),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FSColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FSColors.border),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: FSColors.tealDim, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_downward_rounded, size: 18, color: FSColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.description, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: FSColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: FSColors.tealDim, borderRadius: BorderRadius.circular(4)),
                  child: Text(incomeSourceLabels[entry.source] ?? entry.source, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.teal, fontWeight: FontWeight.w600)),
                ),
                if (date != null) ...[const SizedBox(width: 6), Text(formatDate(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary))],
              ]),
            ])),
            Text(formatINR(entry.amount), style: GoogleFonts.jetBrainsMono(fontSize: 13, color: FSColors.positive, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class AddIncomeSheet extends ConsumerStatefulWidget {
  final IncomeModel? entry;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const AddIncomeSheet({super.key, this.entry, required this.onSave});

  @override
  ConsumerState<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends ConsumerState<AddIncomeSheet> {
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _source = 'salary';
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _amount.text = widget.entry!.amount.toString();
      _desc.text = widget.entry!.description;
      _source = widget.entry!.source;
      _date = DateTime.tryParse(widget.entry!.date) ?? DateTime.now();
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
        'source': _source,
        'description': _desc.text.isEmpty ? _source : _desc.text,
        'date': _date.toIso8601String().split('T')[0],
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.entry == null ? 'Income added' : 'Income updated'))); }
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
        Text('Source', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
        const SizedBox(height: 8),
        FSChipGroup(options: incomeSourceLabels.keys.toList(), selected: _source, onSelect: (v) => setState(() => _source = v)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10), border: Border.all(color: FSColors.border)),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: FSColors.textTertiary),
              const SizedBox(width: 8),
              Text(formatDate(_date), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FSColors.textPrimary)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        FSButton(label: widget.entry == null ? 'Add Income' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
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
import '../../widgets/charts/donut_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(incomeProvider.notifier).refresh(month: _selectedMonth, year: _selectedYear);
    });
  }

  static const _sourceColors = [
    Color(0xFF14B8A6), Color(0xFFF59E0B), Color(0xFF8B5CF6),
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFEF4444),
    Color(0xFFF97316), Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final async = ref.watch(incomeProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/income'),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Income'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () => ref.read(incomeProvider.notifier).refresh(month: _selectedMonth, year: _selectedYear),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (items) {
            final filtered = items;
            final total = filtered.fold(0.0, (s, e) => s + e.amount);
            final bySource = <String, double>{};
            for (final e in filtered) {
              bySource[e.sourceType] = (bySource[e.sourceType] ?? 0) + e.amount;
            }

            final sourceEntries = bySource.entries.toList();
            final sections = sourceEntries.asMap().entries.map((e) => DonutSection(
              label: incomeSourceLabels[e.value.key] ?? e.value.key,
              value: e.value.value,
              color: _sourceColors[e.key % _sourceColors.length],
            )).toList();

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              // Metric row
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Total Income', value: total, accentColor: c.positive, showExact: true)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Entries', value: filtered.length.toDouble(), accentColor: c.teal, isAmount: false)),
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

              // Income by source pie chart
              if (sections.isNotEmpty) ...[
                Text('BY SOURCE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
                const SizedBox(height: 12),
                Center(
                  child: FSDonutChart(sections: sections, centerLabel: 'Total', centerValue: total),
                ).animate(delay: 80.ms).fadeIn(),
                const SizedBox(height: 16),

                // Source breakdown cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sourceEntries.asMap().entries.map((e) {
                      final label = incomeSourceLabels[e.value.key] ?? e.value.key;
                      final color = _sourceColors[e.key % _sourceColors.length];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 4),
                          Text(formatINR(e.value.value), style: GoogleFonts.jetBrainsMono(fontSize: 14, color: c.positive, fontWeight: FontWeight.w600)),
                        ]),
                      );
                    }).toList(),
                  ),
                ).animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: 16),
              ],

              // List
              if (filtered.isEmpty)
                const FSEmptyState(icon: Icons.account_balance_wallet_rounded, title: 'No income recorded', subtitle: 'Tap + to add your first income entry')
              else
                ...filtered.asMap().entries.map((e) => _IncomeRow(
                  entry: e.value,
                  index: e.key,
                  onDetail: () => _showDetail(context, e.value),
                  onDelete: () => _delete(e.value.id),
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
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 0),
    );
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
      ref.read(incomeProvider.notifier).refresh(month: _selectedMonth, year: _selectedYear);
    }
  }

  void _showDetail(BuildContext context, IncomeModel entry) {
    final c = context.fsc;
    final date = DateTime.tryParse(entry.receivedOn);
    showFSBottomSheet(
      context: context,
      title: 'Income Details',
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              _DetailRow(label: 'Description', value: entry.description),
              _DetailRow(label: 'Source', value: incomeSourceLabels[entry.sourceType] ?? entry.sourceType),
              _DetailRow(label: 'Amount', value: formatINR(entry.amount), valueColor: c.positive),
              if (date != null) _DetailRow(label: 'Date', value: formatDate(date)),
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
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: context.fsc.card,
      title: Text('Delete entry?', style: GoogleFonts.plusJakartaSans(color: context.fsc.textPrimary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: context.fsc.negative))),
      ],
    ));
    if (ok == true && mounted) {
      await ref.read(incomeProvider.notifier).remove(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
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

class _IncomeRow extends StatelessWidget {
  final IncomeModel entry;
  final int index;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  const _IncomeRow({required this.entry, required this.index, required this.onDetail, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final date = DateTime.tryParse(entry.receivedOn);
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
              decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_downward_rounded, size: 18, color: c.positive),
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
                  decoration: BoxDecoration(color: c.tealDim, borderRadius: BorderRadius.circular(4)),
                  child: Text(incomeSourceLabels[entry.sourceType] ?? entry.sourceType,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.teal, fontWeight: FontWeight.w600)),
                ),
                if (date != null) ...[
                  const SizedBox(width: 6),
                  Text(formatDate(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
                ],
              ]),
            ])),
            Text(formatINR(entry.amount),
                style: GoogleFonts.jetBrainsMono(fontSize: 13, color: c.positive, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40));
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
      _source = widget.entry!.sourceType;
      _date = DateTime.tryParse(widget.entry!.receivedOn) ?? DateTime.now();
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
        'source_type': _source,
        'description': _desc.text.isEmpty ? _source : _desc.text,
        'received_on': _date.toIso8601String().split('T')[0],
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.entry == null ? 'Income added' : 'Income updated')));
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
        Text('Source', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FSChipGroup(options: incomeSourceLabels.keys.toList(), selected: _source, onSelect: (v) => setState(() => _source = v), labelMap: incomeSourceLabels),
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
        const SizedBox(height: 20),
        FSButton(label: widget.entry == null ? 'Add Income' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

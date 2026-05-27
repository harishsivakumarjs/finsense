import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/trade_model.dart';
import '../../providers/trade_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class TradingScreen extends ConsumerStatefulWidget {
  const TradingScreen({super.key});
  @override
  ConsumerState<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends ConsumerState<TradingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tradeProvider);

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: const Text('Trade Journal'), bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Closed'), Tab(text: 'Open')])),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () => ref.read(tradeProvider.notifier).refresh(),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList()]),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (trades) {
            final closed = trades.where((t) => t.isClosed).toList();
            final open = trades.where((t) => !t.isClosed).toList();
            final totalPnl = closed.fold(0.0, (s, t) => s + (t.netPnl ?? t.computedPnl));
            final wins = closed.where((t) => (t.netPnl ?? t.computedPnl) > 0).length;
            final winRate = closed.isEmpty ? 0.0 : wins / closed.length * 100;
            final best = closed.isEmpty ? 0.0 : closed.map((t) => t.netPnl ?? t.computedPnl).reduce((a, b) => a > b ? a : b);
            final worst = closed.isEmpty ? 0.0 : closed.map((t) => t.netPnl ?? t.computedPnl).reduce((a, b) => a < b ? a : b);

            return NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: FSMetricCard(label: 'Net P&L', value: totalPnl, accentColor: FSColors.amountColor(totalPnl))),
                      const SizedBox(width: 10),
                      Expanded(child: FSMetricCard(label: 'Win Rate', value: winRate, accentColor: FSColors.teal, isAmount: false, subtitle: '${wins}/${closed.length} trades')),
                    ]).animate().fadeIn(),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: FSMetricCard(label: 'Best Trade', value: best, accentColor: FSColors.positive)),
                      const SizedBox(width: 10),
                      Expanded(child: FSMetricCard(label: 'Worst Trade', value: worst, accentColor: FSColors.negative)),
                    ]).animate(delay: 100.ms).fadeIn(),
                  ]),
                )),
              ],
              body: TabBarView(controller: _tabs, children: [
                _TradeList(trades: closed, onEdit: (t) => _openSheet(context, trade: t), onDelete: (id) => _delete(id)),
                _TradeList(trades: open, onEdit: (t) => _openSheet(context, trade: t), onDelete: (id) => _delete(id)),
              ]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openSheet(context), child: const Icon(Icons.add_rounded)),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }

  Future<void> _delete(int id) async {
    await ref.read(tradeProvider.notifier).remove(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade deleted')));
  }

  void _openSheet(BuildContext context, {TradeModel? trade}) {
    showFSBottomSheet(context: context, title: trade == null ? 'Log Trade' : 'Edit Trade',
        builder: (_) => _AddTradeSheet(trade: trade, onSave: (data) async {
          if (trade == null) await ref.read(tradeProvider.notifier).add(data);
          else await ref.read(tradeProvider.notifier).edit(trade.id, data);
        }));
  }
}

class _TradeList extends StatelessWidget {
  final List<TradeModel> trades;
  final void Function(TradeModel) onEdit;
  final void Function(int) onDelete;
  const _TradeList({required this.trades, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) return const FSEmptyState(icon: Icons.candlestick_chart_rounded, title: 'No trades', subtitle: 'Tap + to log a trade');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: trades.length,
      itemBuilder: (_, i) {
        final t = trades[i];
        final pnl = t.netPnl ?? t.computedPnl;
        final date = DateTime.tryParse(t.buyDate);
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: FSColors.redDim, child: const Icon(Icons.delete_rounded, color: FSColors.negative)),
          confirmDismiss: (_) async { onDelete(t.id); return false; },
          child: GestureDetector(
            onTap: () => onEdit(t),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: FSColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(t.scrip, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: FSColors.textPrimary)),
                  Text(formatINR(pnl), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: FSColors.amountColor(pnl))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: FSColors.infoDim, borderRadius: BorderRadius.circular(4)),
                      child: Text(t.tradeType, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FSColors.info, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 6),
                  Text('Buy ₹${t.buyPrice.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
                  if (t.sellPrice != null) ...[
                    Text(' → ₹${t.sellPrice!.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
                  ],
                  const SizedBox(width: 6),
                  Text('Qty ${t.quantity.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
                  const Spacer(),
                  if (date != null) Text(formatDate(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _AddTradeSheet extends ConsumerStatefulWidget {
  final TradeModel? trade;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddTradeSheet({this.trade, required this.onSave});
  @override
  ConsumerState<_AddTradeSheet> createState() => _AddTradeSheetState();
}

class _AddTradeSheetState extends ConsumerState<_AddTradeSheet> {
  final _scrip = TextEditingController();
  final _buyPrice = TextEditingController();
  final _sellPrice = TextEditingController();
  final _qty = TextEditingController();
  final _charges = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'delivery';
  DateTime _buyDate = DateTime.now();
  DateTime? _sellDate;
  bool _loading = false;

  double get _livePnl {
    final bp = double.tryParse(_buyPrice.text) ?? 0;
    final sp = double.tryParse(_sellPrice.text) ?? 0;
    final q = double.tryParse(_qty.text) ?? 0;
    final c = double.tryParse(_charges.text) ?? 0;
    if (sp <= 0) return 0;
    return (sp - bp) * q - c;
  }

  @override
  void initState() {
    super.initState();
    if (widget.trade != null) {
      final t = widget.trade!;
      _scrip.text = t.scrip; _buyPrice.text = t.buyPrice.toString();
      _sellPrice.text = t.sellPrice?.toString() ?? ''; _qty.text = t.quantity.toString();
      _charges.text = t.charges.toString(); _notes.text = t.notes ?? '';
      _type = t.tradeType; _buyDate = DateTime.tryParse(t.buyDate) ?? DateTime.now();
      _sellDate = t.sellDate != null ? DateTime.tryParse(t.sellDate!) : null;
    }
  }

  @override
  void dispose() { _scrip.dispose(); _buyPrice.dispose(); _sellPrice.dispose(); _qty.dispose(); _charges.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_scrip.text.isEmpty || _buyPrice.text.isEmpty || _qty.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = {
        'scrip': _scrip.text, 'trade_type': _type,
        'buy_price': double.tryParse(_buyPrice.text) ?? 0,
        'quantity': double.tryParse(_qty.text) ?? 0,
        'charges': double.tryParse(_charges.text) ?? 0,
        'buy_date': _buyDate.toIso8601String().split('T')[0],
        if (_sellPrice.text.isNotEmpty) 'sell_price': double.tryParse(_sellPrice.text),
        if (_sellDate != null) 'sell_date': _sellDate!.toIso8601String().split('T')[0],
        if (_notes.text.isNotEmpty) 'notes': _notes.text,
      };
      await widget.onSave(data);
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pickDate(bool isBuy) async {
    final d = await showDatePicker(context: context, initialDate: isBuy ? _buyDate : (_sellDate ?? DateTime.now()), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() { if (isBuy) _buyDate = d; else _sellDate = d; });
  }

  @override
  Widget build(BuildContext context) {
    final pnl = _livePnl;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSChipGroup(options: ['intraday','delivery','futures','options'], selected: _type, onSelect: (v) => setState(() => _type = v)),
        const SizedBox(height: 12),
        FSTextField(label: 'Scrip / Symbol', controller: _scrip),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Buy Price', controller: _buyPrice, isAmount: true, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Sell Price (optional)', controller: _sellPrice, isAmount: true, onChanged: (_) => setState(() {}))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FSTextField(label: 'Quantity', controller: _qty, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 10),
          Expanded(child: FSTextField(label: 'Charges', controller: _charges, isAmount: true, onChanged: (_) => setState(() {}))),
        ]),
        if (_sellPrice.text.isNotEmpty && pnl != 0) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: FSColors.amountColor(pnl).withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Net P&L', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textSecondary)),
                Text(formatINR(pnl), style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w600, color: FSColors.amountColor(pnl))),
              ])),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _pickDate(true), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10), border: Border.all(color: FSColors.border)),
            child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: FSColors.textTertiary), const SizedBox(width: 8), Text('Buy: ${formatDate(_buyDate)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textPrimary))]),
          ))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(onTap: () => _pickDate(false), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10), border: Border.all(color: FSColors.border)),
            child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: FSColors.textTertiary), const SizedBox(width: 8), Text(_sellDate != null ? 'Sell: ${formatDate(_sellDate!)}' : 'Sell date', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _sellDate != null ? FSColors.textPrimary : FSColors.textTertiary))]),
          ))),
        ]),
        const SizedBox(height: 10),
        FSTextField(label: 'Notes (optional)', controller: _notes, maxLines: 2),
        const SizedBox(height: 16),
        FSButton(label: widget.trade == null ? 'Log Trade' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

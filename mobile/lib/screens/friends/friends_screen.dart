import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/friend_model.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final async = ref.watch(friendProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/friends'),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: const Text('Friend Ledger'),
      ),
      body: RefreshIndicator(
        color: c.teal,
        backgroundColor: c.card,
        onRefresh: () => ref.read(friendProvider.notifier).refresh(),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [
            FSSkeletonCard(), SizedBox(height: 12), FSSkeletonList(),
          ]),
          error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(color: c.negative))),
          data: (entries) {
            final unsettled = entries.where((e) => !e.isSettled).toList();
            final owed = unsettled.where((e) => e.amount > 0).fold(0.0, (s, e) => s + e.amount);
            final owing = unsettled.where((e) => e.amount < 0).fold(0.0, (s, e) => s + e.amount.abs());
            final net = owed - owing;
            final displayed = _showSettled ? entries : unsettled;

            return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'You Are Owed', value: owed, accentColor: c.positive)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'You Owe', value: owing, accentColor: c.warning)),
              ]).animate().fadeIn(),
              const SizedBox(height: 12),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('ENTRIES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 1)),
                GestureDetector(
                  onTap: () => setState(() => _showSettled = !_showSettled),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _showSettled ? c.tealDim : c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _showSettled ? c.teal.withAlpha(80) : c.border),
                    ),
                    child: Text(_showSettled ? 'All' : 'Unsettled',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _showSettled ? c.teal : c.textTertiary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              if (displayed.isEmpty)
                FSEmptyState(
                  icon: Icons.people_rounded,
                  title: _showSettled ? 'No entries' : 'All settled up!',
                  subtitle: _showSettled ? 'Tap + to add a ledger entry' : 'No pending balances with friends',
                )
              else
                ...displayed.asMap().entries.map((e) => _FriendRow(
                  entry: e.value,
                  index: e.key,
                  onEdit: () => _openSheet(context, entry: e.value),
                  onSettle: () => _settle(e.value.id),
                  onDelete: () => _delete(e.value.id),
                )),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Net Position', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  Text(formatINR(net), style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w600, color: c.amountColor(net))),
                ]),
              ),
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

  Future<void> _settle(String id) async {
    final c = context.fsc;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Settle this entry?', style: GoogleFonts.plusJakartaSans(color: c.textPrimary)),
      content: Text('Mark this as settled. This cannot be undone.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Settle', style: TextStyle(color: c.positive))),
      ],
    ));
    if (ok == true && mounted) {
      await ref.read(friendProvider.notifier).settle(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settled')));
    }
  }

  Future<void> _delete(String id) async {
    await ref.read(friendProvider.notifier).remove(id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
  }

  void _openSheet(BuildContext context, {FriendModel? entry}) {
    showFSBottomSheet(context: context, title: entry == null ? 'Add Entry' : 'Edit Entry',
        builder: (_) => _AddFriendSheet(entry: entry, onSave: (data) async {
          if (entry == null) await ref.read(friendProvider.notifier).add(data);
          else await ref.read(friendProvider.notifier).edit(entry.id, data);
        }));
  }
}

class _FriendRow extends StatelessWidget {
  final FriendModel entry;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onSettle;
  final VoidCallback onDelete;
  const _FriendRow({required this.entry, required this.index, required this.onEdit, required this.onSettle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final date = DateTime.tryParse(entry.date);
    final color = entry.isSettled ? c.textTertiary : (entry.theyOweMe ? c.positive : c.warning);
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(
        alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), color: c.greenDim,
        child: Icon(Icons.check_rounded, color: c.positive),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: c.redDim,
        child: Icon(Icons.delete_rounded, color: c.negative),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) { onSettle(); return false; }
        onDelete(); return false;
      },
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: entry.isSettled ? c.border.withAlpha(60) : c.border),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
              child: Center(child: Text(entry.initials, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(entry.friendName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: entry.isSettled ? c.textTertiary : c.textPrimary)),
                if (entry.isSettled) ...[const SizedBox(width: 6), Icon(Icons.check_circle_rounded, size: 14, color: c.positive)],
              ]),
              Text(entry.reason, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (date != null) Text(timeAgo(date), style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatINR(entry.amount.abs()), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              Text(entry.theyOweMe ? 'owes you' : 'you owe', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
            ]),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40));
  }
}

class _AddFriendSheet extends ConsumerStatefulWidget {
  final FriendModel? entry;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddFriendSheet({this.entry, required this.onSave});
  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _theyOweMe = true;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final e = widget.entry!;
      _name.text = e.friendName; _amount.text = e.amount.abs().toString(); _reason.text = e.reason;
      _theyOweMe = e.amount > 0; _date = DateTime.tryParse(e.date) ?? DateTime.now();
    }
  }

  @override
  void dispose() { _name.dispose(); _amount.dispose(); _reason.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_name.text.isEmpty || _amount.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final rawAmount = double.tryParse(_amount.text) ?? 0;
      await widget.onSave({
        'friend_name': _name.text,
        'amount': _theyOweMe ? rawAmount : -rawAmount,
        'reason': _reason.text,
        'date': _date.toIso8601String().split('T')[0],
        'is_settled': false,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSTextField(label: 'Friend Name', controller: _name),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _theyOweMe = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _theyOweMe ? c.positive.withAlpha(30) : c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _theyOweMe ? c.positive.withAlpha(80) : c.border),
              ),
              child: Center(child: Text('They owe me', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _theyOweMe ? c.positive : c.textTertiary))),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _theyOweMe = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_theyOweMe ? c.warning.withAlpha(30) : c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: !_theyOweMe ? c.warning.withAlpha(80) : c.border),
              ),
              child: Center(child: Text('I owe them', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: !_theyOweMe ? c.warning : c.textTertiary))),
            ),
          )),
        ]),
        const SizedBox(height: 12),
        FSTextField(label: 'Amount', controller: _amount, isAmount: true),
        const SizedBox(height: 12),
        FSTextField(label: 'Reason', controller: _reason),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: c.textTertiary),
              const SizedBox(width: 8),
              Text(formatDate(_date), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.textPrimary)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        FSButton(label: widget.entry == null ? 'Add Entry' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

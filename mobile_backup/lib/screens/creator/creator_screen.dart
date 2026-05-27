import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/creator_model.dart';
import '../../providers/creator_provider.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_bottom_sheet.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class CreatorScreen extends ConsumerStatefulWidget {
  const CreatorScreen({super.key});
  @override
  ConsumerState<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends ConsumerState<CreatorScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(creatorProvider);

    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: const Text('Creator Income')),
      body: RefreshIndicator(
        color: FSColors.teal,
        backgroundColor: FSColors.card,
        onRefresh: () => ref.read(creatorProvider.notifier).refresh(),
        child: async.when(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: [const FSSkeletonCard(), const SizedBox(height: 12), const FSSkeletonList()]),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) {
            final adsense = entries.where((e) => e.incomeType == 'adsense').fold(0.0, (s, e) => s + e.amount);
            final sponsorships = entries.where((e) => e.incomeType == 'sponsorship').fold(0.0, (s, e) => s + e.amount);
            final memberships = entries.where((e) => e.incomeType == 'membership').fold(0.0, (s, e) => s + e.amount);
            final total = entries.fold(0.0, (s, e) => s + e.amount);

            return ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: FSMetricCard(label: 'AdSense', value: adsense, accentColor: FSColors.warning)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Sponsorships', value: sponsorships, accentColor: FSColors.purple)),
              ]).animate().fadeIn(),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: FSMetricCard(label: 'Memberships', value: memberships, accentColor: FSColors.info)),
                const SizedBox(width: 10),
                Expanded(child: FSMetricCard(label: 'Total', value: total, accentColor: FSColors.positive)),
              ]).animate(delay: 80.ms).fadeIn(),
              const SizedBox(height: 16),
              Text('ALL ENTRIES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const FSEmptyState(icon: Icons.video_library_rounded, title: 'No creator income', subtitle: 'Log your AdSense, brand deals and memberships')
              else
                ...entries.map((e) => _CreatorRow(entry: e, onEdit: () => _openSheet(context, entry: e), onDelete: () => _delete(e.id))),
              const SizedBox(height: 80),
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openSheet(context), child: const Icon(Icons.add_rounded)),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }

  Future<void> _delete(int id) async { await ref.read(creatorProvider.notifier).remove(id); }

  void _openSheet(BuildContext context, {CreatorModel? entry}) {
    showFSBottomSheet(context: context, title: entry == null ? 'Log Creator Income' : 'Edit Entry',
        builder: (_) => _AddCreatorSheet(entry: entry, onSave: (data) async {
          if (entry == null) await ref.read(creatorProvider.notifier).add(data);
          else await ref.read(creatorProvider.notifier).edit(entry.id, data);
        }));
  }
}

class _CreatorRow extends StatelessWidget {
  final CreatorModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CreatorRow({required this.entry, required this.onEdit, required this.onDelete});

  static const _typeColors = {
    'adsense': FSColors.warning, 'sponsorship': FSColors.purple,
    'membership': FSColors.info, 'merch': FSColors.teal,
    'course': FSColors.positive, 'other': FSColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[entry.incomeType] ?? FSColors.textSecondary;
    final date = DateTime.tryParse(entry.date);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: FSColors.redDim, child: const Icon(Icons.delete_rounded, color: FSColors.negative)),
      confirmDismiss: (_) async { onDelete(); return false; },
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: FSColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: FSColors.border)),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.brandName ?? entry.videoTitle ?? entry.incomeType, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: FSColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                    child: Text(entry.incomeType, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color, fontWeight: FontWeight.w600))),
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

class _AddCreatorSheet extends ConsumerStatefulWidget {
  final CreatorModel? entry;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AddCreatorSheet({this.entry, required this.onSave});
  @override
  ConsumerState<_AddCreatorSheet> createState() => _AddCreatorSheetState();
}

class _AddCreatorSheetState extends ConsumerState<_AddCreatorSheet> {
  final _amount = TextEditingController();
  final _brand = TextEditingController();
  final _video = TextEditingController();
  final _rpm = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'adsense';
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final e = widget.entry!;
      _amount.text = e.amount.toString(); _brand.text = e.brandName ?? '';
      _video.text = e.videoTitle ?? ''; _rpm.text = e.rpm?.toString() ?? '';
      _notes.text = e.notes ?? ''; _type = e.incomeType;
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
    }
  }

  @override
  void dispose() { _amount.dispose(); _brand.dispose(); _video.dispose(); _rpm.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_amount.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'income_type': _type, 'amount': double.tryParse(_amount.text) ?? 0,
        if (_brand.text.isNotEmpty) 'brand_name': _brand.text,
        if (_video.text.isNotEmpty) 'video_title': _video.text,
        'date': _date.toIso8601String().split('T')[0],
        if (_rpm.text.isNotEmpty) 'rpm': double.tryParse(_rpm.text),
        if (_notes.text.isNotEmpty) 'notes': _notes.text,
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FSChipGroup(options: const ['adsense','sponsorship','membership','merch','course','other'], selected: _type, onSelect: (v) => setState(() => _type = v)),
        const SizedBox(height: 12),
        FSTextField(label: 'Amount', controller: _amount, isAmount: true),
        const SizedBox(height: 10),
        FSTextField(label: 'Brand Name (optional)', controller: _brand),
        const SizedBox(height: 10),
        FSTextField(label: 'Video Title (optional)', controller: _video),
        if (_type == 'adsense') ...[
          const SizedBox(height: 10),
          FSTextField(label: 'RPM (optional)', controller: _rpm, keyboardType: TextInputType.number),
        ],
        const SizedBox(height: 10),
        GestureDetector(onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
          if (d != null) setState(() => _date = d);
        }, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10), border: Border.all(color: FSColors.border)),
          child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: FSColors.textTertiary), const SizedBox(width: 8), Text(formatDate(_date), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: FSColors.textPrimary))]),
        )),
        const SizedBox(height: 10),
        FSTextField(label: 'Notes (optional)', controller: _notes, maxLines: 2),
        const SizedBox(height: 16),
        FSButton(label: widget.entry == null ? 'Log Income' : 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 8),
      ]),
    );
  }
}

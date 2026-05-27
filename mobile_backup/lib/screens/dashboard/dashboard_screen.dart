import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/dashboard_model.dart';
import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../widgets/common/fs_card.dart';
import '../../widgets/common/fs_metric_card.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_alert_card.dart';
import '../../widgets/common/fs_amount_display.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _dtiColor(double v) {
    if (v < 20) return FSColors.positive;
    if (v < 40) return FSColors.info;
    if (v < 70) return FSColors.warning;
    return FSColors.negative;
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider).value;
    final userName = auth?.user?.name.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: FSColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: FSColors.teal,
          backgroundColor: FSColors.card,
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: FSColors.background,
                floating: true,
                snap: true,
                titleSpacing: 20,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()},', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textTertiary)),
                    Text(userName, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: FSColors.textPrimary)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: FSColors.textSecondary),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: dashAsync.when(
                  loading: () => SliverList(delegate: SliverChildListDelegate([
                    const FSSkeletonCard(), const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: const FSSkeletonCard()),
                      const SizedBox(width: 10),
                      Expanded(child: const FSSkeletonCard()),
                      const SizedBox(width: 10),
                      Expanded(child: const FSSkeletonCard()),
                    ]),
                  ])),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading dashboard', style: GoogleFonts.plusJakartaSans(color: FSColors.negative))),
                  ),
                  data: (dash) => SliverList(delegate: SliverChildListDelegate([
                    if (dash != null) ..._buildContent(dash),
                  ])),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAdd(context),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 0),
    );
  }

  List<Widget> _buildContent(DashboardModel dash) {
    return [
      // Net worth card
      FSCard(
        accentTop: FSColors.teal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NET WORTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
                Row(children: [
                  Icon(dash.netWorthChange >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14, color: FSColors.amountColor(dash.netWorthChange)),
                  const SizedBox(width: 4),
                  FSAmountDisplay(amount: dash.netWorthChange, fontSize: 12, compact: true),
                  Text(' this month', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Text(formatINR(dash.netWorth), style: GoogleFonts.jetBrainsMono(fontSize: 30, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
      const SizedBox(height: 12),

      // Metric row
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          SizedBox(width: 140, child: FSMetricCard(label: 'Free Cash', value: dash.freeCash, accentColor: FSColors.info)),
          const SizedBox(width: 10),
          SizedBox(width: 140, child: FSMetricCard(label: 'Debt Score', value: dash.debtScore,
              accentColor: dash.debtScore < 40 ? FSColors.positive : dash.debtScore < 70 ? FSColors.warning : FSColors.negative,
              isAmount: false, subtitle: dash.debtScore < 40 ? 'Safe' : dash.debtScore < 70 ? 'Caution' : 'Danger')),
          const SizedBox(width: 10),
          SizedBox(width: 140, child: FSMetricCard(label: 'Tax Due', value: dash.taxDue, accentColor: dash.taxDue > 0 ? FSColors.negative : FSColors.positive)),
        ]),
      ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
      const SizedBox(height: 14),

      // Alert
      if (dash.alertMessage != null) ...[
        FSAlertCard(message: dash.alertMessage!).animate(delay: 150.ms).fadeIn(),
        const SizedBox(height: 14),
      ],

      // Income vs Expenses
      FSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THIS MONTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 14),
            _buildBar('Income', dash.totalIncome, dash.totalIncome + dash.totalExpenses, FSColors.positive),
            const SizedBox(height: 10),
            _buildBar('Expenses', dash.totalExpenses, dash.totalIncome + dash.totalExpenses, FSColors.negative),
          ],
        ),
      ).animate(delay: 200.ms).fadeIn(),
      const SizedBox(height: 14),

      // DTI chart
      if (dash.dtiHistory.isNotEmpty) ...[
        FSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('6-MONTH DEBT RATIO', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 14),
              FSBarChart(
                data: dash.dtiHistory.map((p) => {'month': p.month, 'dti': p.dti}).toList(),
                xKey: 'month',
                yKey: 'dti',
                colorFn: _dtiColor,
                height: 160,
              ),
            ],
          ),
        ).animate(delay: 250.ms).fadeIn(),
        const SizedBox(height: 14),
      ],

      // Recent Activity
      FSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RECENT ACTIVITY', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            if (dash.recentActivity.isEmpty)
              const FSEmptyState(icon: Icons.receipt_long_rounded, title: 'No activity yet', subtitle: 'Start tracking your finances')
            else
              ...dash.recentActivity.map((a) => _ActivityRow(activity: a)),
          ],
        ),
      ).animate(delay: 300.ms).fadeIn(),
      const SizedBox(height: 80),
    ];
  }

  Widget _buildBar(String label, double value, double total, Color color) {
    final fraction = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textSecondary)),
        Text(formatINRCompact(value), style: GoogleFonts.jetBrainsMono(fontSize: 12, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction,
          backgroundColor: FSColors.tertiary,
          color: color,
          minHeight: 6,
        ),
      ),
    ]);
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FSColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _QuickAddSheet(),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final DashboardActivity activity;
  const _ActivityRow({required this.activity});

  (IconData, Color) get _meta {
    switch (activity.type) {
      case 'income': return (Icons.arrow_downward_rounded, FSColors.positive);
      case 'trade': return (Icons.candlestick_chart_rounded, FSColors.info);
      default:
        switch (activity.category) {
          case 'food': return (Icons.restaurant_rounded, FSColors.warning);
          case 'transport': return (Icons.directions_car_rounded, FSColors.info);
          case 'health': return (Icons.favorite_rounded, FSColors.negative);
          case 'entertainment': return (Icons.movie_rounded, FSColors.purple);
          case 'shopping': return (Icons.shopping_bag_rounded, FSColors.purple);
          default: return (Icons.receipt_rounded, FSColors.textSecondary);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _meta;
    final date = DateTime.tryParse(activity.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(activity.description, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: FSColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (date != null) Text(timeAgo(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
        ])),
        FSAmountDisplay(amount: activity.amount, fontSize: 13),
      ]),
    );
  }
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet();

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  String _tab = 'expense';
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _category = 'food';
  String _source = 'salary';
  bool _loading = false;

  @override
  void dispose() { _amount.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_amount.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (_tab == 'expense') {
        await ref.read(expenseProvider.notifier).add({
          'amount': double.parse(_amount.text),
          'category': _category,
          'description': _desc.text.isEmpty ? _category : _desc.text,
          'date': today,
        });
      } else {
        await ref.read(incomeProvider.notifier).add({
          'amount': double.parse(_amount.text),
          'source': _source,
          'description': _desc.text.isEmpty ? _source : _desc.text,
          'date': today,
        });
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_tab == 'expense' ? 'Expense' : 'Income'} added')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: FSColors.textTertiary.withAlpha(80), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: FSColors.tertiary, borderRadius: BorderRadius.circular(10)),
          child: Row(children: ['expense', 'income'].map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == t ? FSColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(t == 'expense' ? 'Expense' : 'Income',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _tab == t ? const Color(0xFF0F1117) : FSColors.textTertiary))),
              ),
            ),
          )).toList()),
        ),
        const SizedBox(height: 16),
        FSTextField(label: 'Amount', controller: _amount, isAmount: true, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        FSTextField(label: 'Description (optional)', controller: _desc),
        const SizedBox(height: 12),
        if (_tab == 'expense') ...[
          Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
          const SizedBox(height: 8),
          FSChipGroup(options: expenseCategoryLabels.keys.toList(), selected: _category, onSelect: (v) => setState(() => _category = v)),
        ] else ...[
          Text('Source', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
          const SizedBox(height: 8),
          FSChipGroup(options: incomeSourceLabels.keys.toList(), selected: _source, onSelect: (v) => setState(() => _source = v)),
        ],
        const SizedBox(height: 20),
        FSButton(label: 'Save', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
        const SizedBox(height: 16),
      ]),
    );
  }
}

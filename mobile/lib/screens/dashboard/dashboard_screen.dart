import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/fs_color_scheme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/dashboard_model.dart';
import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/trade_provider.dart';
import '../../widgets/common/fs_empty_state.dart';
import '../../widgets/common/fs_loading_skeleton.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/common/fs_category_chip.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/fs_nav_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final dashAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider).value;
    final userName = auth?.user?.name.split(' ').first ?? 'there';
    final initials = auth?.user?.initials ?? 'U';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.background,
      drawer: const FSNavDrawer(currentRoute: '/dashboard'),
      body: SafeArea(
        child: RefreshIndicator(
          color: c.teal,
          backgroundColor: c.card,
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.teal),
                          child: Center(
                            child: Text(initials, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_greeting(), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textTertiary)),
                          Text(userName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                        ]),
                      ),
                      IconButton(
                        icon: Icon(Icons.search_rounded, color: c.textSecondary, size: 22),
                        onPressed: () => _showSearch(context),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications_outlined, color: c.textSecondary, size: 24),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              backgroundColor: c.card,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                              builder: (_) => const _NotificationsSheet(),
                            ),
                          ),
                          Positioned(
                            top: 10, right: 10,
                            child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.negative, shape: BoxShape.circle)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: dashAsync.when(
                  loading: () => SliverList(delegate: SliverChildListDelegate([
                    const FSSkeletonCard(), const SizedBox(height: 12),
                    Row(children: const [Expanded(child: FSSkeletonCard()), SizedBox(width: 8), Expanded(child: FSSkeletonCard()), SizedBox(width: 8), Expanded(child: FSSkeletonCard())]),
                  ])),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading dashboard', style: GoogleFonts.plusJakartaSans(color: c.negative))),
                  ),
                  data: (dash) => SliverList(
                    delegate: SliverChildListDelegate(dash != null ? _buildContent(context, dash) : []),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAdd(context),
        backgroundColor: c.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 2),
    );
  }

  List<Widget> _buildContent(BuildContext context, DashboardModel dash) {
    final c = context.fsc;
    final savings = dash.totalIncome - dash.totalExpenses;
    final savingsPct = dash.totalIncome > 0 ? (savings / dash.totalIncome * 100).clamp(-99, 99) : 0.0;
    final netWorthPct = dash.netWorth != 0 ? (dash.netWorthChange / dash.netWorth.abs() * 100).clamp(-99, 99) : 0.0;

    return [
      // Net Worth Card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('NET WORTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.teal, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (dash.netWorthChange >= 0 ? c.positive : c.negative).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(dash.netWorthChange >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: dash.netWorthChange >= 0 ? c.positive : c.negative),
                  const SizedBox(width: 3),
                  Text('${netWorthPct.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: dash.netWorthChange >= 0 ? c.positive : c.negative)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Text(formatINR(dash.netWorth), style: GoogleFonts.jetBrainsMono(fontSize: 30, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(
              dash.netWorthChange >= 0 ? '+${formatINRCompact(dash.netWorthChange)} this month' : '${formatINRCompact(dash.netWorthChange)} this month',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: dash.netWorthChange >= 0 ? c.positive : c.negative),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04),
      const SizedBox(height: 16),

      // 3-col metrics
      Row(children: [
        _MetricCard(label: 'Cash', value: formatINRCompact(dash.freeCash), icon: Icons.account_balance_wallet_outlined, color: c.info),
        const SizedBox(width: 10),
        _MetricCard(label: 'Debt Score', value: '${dash.debtScore.toStringAsFixed(0)}%', icon: Icons.credit_score_outlined,
            color: dash.debtScore < 30 ? c.positive : dash.debtScore < 60 ? c.warning : c.negative),
        const SizedBox(width: 10),
        _MetricCard(label: 'Tax Due', value: formatINRCompact(dash.taxDue), icon: Icons.receipt_outlined, color: dash.taxDue > 0 ? c.negative : c.positive),
      ]).animate(delay: 80.ms).fadeIn(),
      const SizedBox(height: 16),

      // Alert
      if (dash.alertMessage != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.warning.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.warning.withAlpha(60)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: c.warning, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(dash.alertMessage!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.warning, fontWeight: FontWeight.w500))),
          ]),
        ).animate(delay: 120.ms).fadeIn(),
        const SizedBox(height: 16),
      ],

      // This Month card
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('THIS MONTH', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
            Text(
              const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][DateTime.now().month - 1],
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: c.teal),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _SummaryCol(label: 'Income', value: formatINRCompact(dash.totalIncome), color: c.positive, icon: Icons.arrow_upward_rounded),
            _divider(c),
            _SummaryCol(label: 'Expenses', value: formatINRCompact(dash.totalExpenses), color: c.negative, icon: Icons.arrow_downward_rounded),
            _divider(c),
            _SummaryCol(
              label: 'Savings',
              value: formatINRCompact(savings.abs()),
              color: savings >= 0 ? c.teal : c.negative,
              icon: savings >= 0 ? Icons.savings_outlined : Icons.trending_down_rounded,
              subLabel: '${savingsPct >= 0 ? '+' : ''}${savingsPct.toStringAsFixed(0)}%',
            ),
          ]),
        ]),
      ).animate(delay: 160.ms).fadeIn(),
      const SizedBox(height: 16),

      // Income vs Expense bar graph card
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('INCOME & EXPENSES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
          const SizedBox(height: 16),
          _IncomeExpenseBar(label: 'Income', value: dash.totalIncome, max: [dash.totalIncome, dash.totalExpenses].reduce((a, b) => a > b ? a : b), color: c.positive),
          const SizedBox(height: 10),
          _IncomeExpenseBar(label: 'Expenses', value: dash.totalExpenses, max: [dash.totalIncome, dash.totalExpenses].reduce((a, b) => a > b ? a : b), color: c.negative),
          const SizedBox(height: 10),
          _IncomeExpenseBar(label: 'Savings', value: savings.abs(), max: [dash.totalIncome, dash.totalExpenses].reduce((a, b) => a > b ? a : b), color: savings >= 0 ? c.teal : c.negative),
        ]),
      ).animate(delay: 200.ms).fadeIn(),
      const SizedBox(height: 16),

      // Recent Activity
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('RECENT ACTIVITY', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0.8)),
            GestureDetector(
              onTap: () => context.go('/income'),
              child: Text('See All', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          if (dash.recentActivity.isEmpty)
            const FSEmptyState(icon: Icons.receipt_long_rounded, title: 'No activity yet', subtitle: 'Start tracking your finances')
          else
            ...dash.recentActivity.take(5).map((a) => _ActivityRow(activity: a)),
        ]),
      ).animate(delay: 220.ms).fadeIn(),
      const SizedBox(height: 90),
    ];
  }

  Widget _divider(FSColorScheme c) => Container(width: 1, height: 50, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 8));

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SearchDialog(onNavigate: (route) {
        Navigator.of(context, rootNavigator: true).pop();
        context.go(route);
      }),
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.fsc.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _QuickAddSheet(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(context.isDark ? 25 : 6), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
        ]),
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subLabel;
  const _SummaryCol({required this.label, required this.value, required this.color, required this.icon, this.subLabel});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Expanded(
      child: Column(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: c.textTertiary)),
        if (subLabel != null) ...[
          const SizedBox(height: 2),
          Text(subLabel!, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final DashboardActivity activity;
  const _ActivityRow({required this.activity});

  (IconData, Color) _meta(BuildContext context) {
    final c = context.fsc;
    switch (activity.type) {
      case 'income': return (Icons.arrow_circle_down_rounded, c.positive);
      case 'trade': return (Icons.candlestick_chart_rounded, c.info);
      default:
        switch (activity.category) {
          case 'food': return (Icons.restaurant_rounded, c.warning);
          case 'transport': return (Icons.directions_car_rounded, c.info);
          case 'health': return (Icons.favorite_rounded, c.negative);
          case 'entertainment': return (Icons.movie_rounded, c.purple);
          case 'shopping': return (Icons.shopping_bag_rounded, c.purple);
          default: return (Icons.receipt_rounded, c.textSecondary);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final (icon, color) = _meta(context);
    final isIncome = activity.type == 'income';
    final date = DateTime.tryParse(activity.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(activity.description, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (date != null) Text(timeAgo(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
        ])),
        Text(
          '${isIncome ? '+' : '-'}${formatINR(activity.amount.abs())}',
          style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: isIncome ? c.positive : c.negative),
        ),
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
          'spent_on': today,
        });
      } else {
        await ref.read(incomeProvider.notifier).add({
          'amount': double.parse(_amount.text),
          'source_type': _source,
          'description': _desc.text.isEmpty ? _source : _desc.text,
          'received_on': today,
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
    final c = context.fsc;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16, left: 20, right: 20, top: 8),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textTertiary.withAlpha(60), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Quick Add', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(children: ['expense', 'income'].map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == t ? c.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(
                  t == 'expense' ? 'Expense' : 'Income',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _tab == t ? Colors.white : c.textTertiary),
                )),
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
          Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FSChipGroup(options: expenseCategoryLabels.keys.toList(), selected: _category, onSelect: (v) => setState(() => _category = v)),
        ] else ...[
          Text('Source', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FSChipGroup(options: incomeSourceLabels.keys.toList(), selected: _source, onSelect: (v) => setState(() => _source = v)),
        ],
        const SizedBox(height: 20),
        FSButton(label: 'Save', onPressed: _loading ? null : _save, isLoading: _loading, fullWidth: true),
      ]),
    );
  }
}

class _IncomeExpenseBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  const _IncomeExpenseBar({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(children: [
      SizedBox(
        width: 64,
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textSecondary)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, backgroundColor: c.surface, color: color, minHeight: 8),
        ),
      ),
      const SizedBox(width: 10),
      Text(formatINRCompact(value), style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

class _SearchItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color? color;
  const _SearchItem({required this.icon, required this.title, required this.subtitle, required this.route, this.color});
}

class _SearchDialog extends ConsumerStatefulWidget {
  final void Function(String) onNavigate;
  const _SearchDialog({required this.onNavigate});

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  String _query = '';

  static final _pages = [
    (Icons.arrow_circle_up_outlined, 'Income', '/income'),
    (Icons.arrow_circle_down_outlined, 'Expenses', '/expenses'),
    (Icons.show_chart_rounded, 'Net Worth', '/networth'),
    (Icons.credit_card_outlined, 'Debt', '/debt'),
    (Icons.pie_chart_rounded, 'Investments', '/investments'),
    (Icons.trending_up_rounded, 'Trading', '/trading'),
    (Icons.video_library_rounded, 'Creator', '/creator'),
    (Icons.people_outlined, 'Friends', '/friends'),
    (Icons.verified_user_rounded, 'Insurance', '/insurance'),
    (Icons.calculate_rounded, 'Simulator', '/simulator'),
    (Icons.receipt_long_rounded, 'Tax', '/tax'),
  ];

  List<_SearchItem> _getResults() {
    if (_query.isEmpty) {
      return _pages
          .map((p) => _SearchItem(icon: p.$1, title: p.$2, subtitle: 'Page', route: p.$3))
          .toList();
    }

    final q = _query.toLowerCase();
    final results = <_SearchItem>[];

    // Income entries
    for (final e in ref.read(incomeProvider).value ?? []) {
      if (e.description.toLowerCase().contains(q) ||
          (incomeSourceLabels[e.sourceType] ?? e.sourceType).toLowerCase().contains(q)) {
        results.add(_SearchItem(
          icon: Icons.arrow_downward_rounded,
          title: e.description.isEmpty ? (incomeSourceLabels[e.sourceType] ?? e.sourceType) : e.description,
          subtitle: '${incomeSourceLabels[e.sourceType] ?? e.sourceType} · ${formatINR(e.amount)}',
          route: '/income',
          color: const Color(0xFF10B981),
        ));
      }
    }

    // Expense entries
    for (final e in ref.read(expenseProvider).value ?? []) {
      if (e.description.toLowerCase().contains(q) ||
          (expenseCategoryLabels[e.category] ?? e.category).toLowerCase().contains(q)) {
        results.add(_SearchItem(
          icon: Icons.receipt_outlined,
          title: e.description.isEmpty ? (expenseCategoryLabels[e.category] ?? e.category) : e.description,
          subtitle: '${expenseCategoryLabels[e.category] ?? e.category} · ${formatINR(e.amount)}',
          route: '/expenses',
          color: const Color(0xFFEF4444),
        ));
      }
    }

    // Trades
    for (final t in ref.read(tradeProvider).value ?? []) {
      if (t.scrip.toLowerCase().contains(q) || t.tradeType.toLowerCase().contains(q)) {
        results.add(_SearchItem(
          icon: Icons.candlestick_chart_rounded,
          title: t.scrip,
          subtitle: '${t.tradeType.toUpperCase()} · ${t.isClosed ? 'Closed' : 'Open'}',
          route: '/trading',
          color: const Color(0xFF3B82F6),
        ));
      }
    }

    // Page names
    for (final p in _pages) {
      if (p.$2.toLowerCase().contains(q)) {
        results.add(_SearchItem(icon: p.$1, title: p.$2, subtitle: 'Page', route: p.$3));
      }
    }

    return results.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final results = _getResults();

    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search entries, trades, pages...',
              hintStyle: GoogleFonts.plusJakartaSans(color: c.textTertiary),
              prefixIcon: Icon(Icons.search_rounded, color: c.textTertiary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.teal)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          if (_query.isNotEmpty && results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No results for "$_query"', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textTertiary)),
            )
          else
            ...results.map((r) => ListTile(
              dense: true,
              leading: Icon(r.icon, size: 18, color: r.color ?? c.teal),
              title: Text(r.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(r.subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textTertiary)),
              trailing: Icon(Icons.chevron_right_rounded, size: 16, color: c.textTertiary),
              onTap: () => widget.onNavigate(r.route),
            )),
        ]),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textTertiary.withAlpha(60), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Notifications', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(height: 16),
        const FSEmptyState(icon: Icons.notifications_none_rounded, title: 'No new notifications', subtitle: "You're all caught up"),
        const SizedBox(height: 16),
      ]),
    );
  }
}

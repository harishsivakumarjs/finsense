import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/fs_card.dart';
import '../../widgets/common/fs_text_field.dart';
import '../../widgets/common/fs_button.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

int calculateDebtScore(double income, double totalEmi, double ccMin, double savings, double emergencyFund) {
  if (income == 0) return 0;
  final totalDebt = totalEmi + ccMin;
  final dti = totalDebt / income;
  double score = 0;

  if (dti >= 0.7) score += 60;
  else if (dti >= 0.5) score += 45;
  else if (dti >= 0.4) score += 30;
  else if (dti >= 0.3) score += 15;
  else score += dti * 50;

  final savingsRate = savings / income;
  if (savingsRate < 0.05) score += 15;
  else if (savingsRate < 0.1) score += 10;
  else if (savingsRate < 0.2) score += 5;

  final months = income > 0 ? emergencyFund / income : 0;
  if (months < 1) score += 10;
  else if (months < 3) score += 5;

  if (ccMin > 0) {
    final ccRatio = ccMin / income;
    score += (ccRatio * 30).clamp(0, 15);
  }

  return score.round().clamp(0, 100);
}

class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});
  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  double _income = 80000;
  double _totalEmi = 15000;
  double _expenses = 30000;
  double _savings = 10000;

  final _emiInput = TextEditingController();
  final _rateInput = TextEditingController();
  Map<String, dynamic>? _skipResult;

  double get _dti => _income > 0 ? _totalEmi / _income : 0;
  double get _freeCash => _income - _totalEmi - _expenses;
  double get _savingsRate => _income > 0 ? _savings / _income : 0;
  int get _score => calculateDebtScore(_income, _totalEmi, 0, _savings, _income * 3);

  Color get _scoreColor {
    if (_score < 40) return FSColors.positive;
    if (_score < 70) return FSColors.warning;
    return FSColors.negative;
  }

  String get _verdict {
    if (_score < 40) return 'Safe zone — your debt is well managed.';
    if (_score < 70) return 'Caution — one income dip could create pressure.';
    return 'Danger — EMIs are consuming too much income.';
  }

  Color _dtiColor(double v) {
    if (v < 20) return FSColors.positive;
    if (v < 40) return FSColors.info;
    if (v < 70) return FSColors.warning;
    return FSColors.negative;
  }

  List<Map<String, dynamic>> get _forecastData {
    return List.generate(6, (i) {
      final months = i + 1;
      final projectedIncome = _income * (1 + 0.005 * months);
      final dtiPct = projectedIncome > 0 ? (_totalEmi / projectedIncome * 100) : 0.0;
      return {'month': 'M+$months', 'dti': dtiPct};
    });
  }

  @override
  void dispose() { _emiInput.dispose(); _rateInput.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FSColors.background,
      appBar: AppBar(title: const Text('What-If Simulator')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Section 1: Sliders
        FSCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ADJUST SCENARIO', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 16),
            _Slider(label: 'Monthly Income', value: _income, min: 0, max: 500000, step: 1000, onChanged: (v) => setState(() => _income = v)),
            const SizedBox(height: 12),
            _Slider(label: 'Total EMIs', value: _totalEmi, min: 0, max: 200000, step: 500, onChanged: (v) => setState(() => _totalEmi = v)),
            const SizedBox(height: 12),
            _Slider(label: 'Monthly Expenses', value: _expenses, min: 0, max: 200000, step: 500, onChanged: (v) => setState(() => _expenses = v)),
            const SizedBox(height: 12),
            _Slider(label: 'Monthly Savings', value: _savings, min: 0, max: 100000, step: 500, onChanged: (v) => setState(() => _savings = v)),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 14),

        // Section 2: Skip EMI
        FSCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SKIP EMI CALCULATOR', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FSTextField(label: 'EMI Amount', controller: _emiInput, isAmount: true)),
              const SizedBox(width: 10),
              Expanded(child: FSTextField(label: 'Interest Rate %', controller: _rateInput, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            FSButton(label: 'Calculate', onPressed: _calculateSkip, style: FSButtonStyle.ghost),
            if (_skipResult != null) ...[
              const SizedBox(height: 12),
              ..._skipResult!.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textSecondary)),
                  Text('${e.value}', style: GoogleFonts.jetBrainsMono(fontSize: 13, color: FSColors.textPrimary, fontWeight: FontWeight.w500)),
                ]),
              )),
            ],
          ]),
        ).animate(delay: 80.ms).fadeIn(),
        const SizedBox(height: 14),

        // Section 3: Results
        FSCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LIVE RESULTS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _ResultStat(label: 'DTI', value: '${(_dti * 100).toStringAsFixed(1)}%', color: _dtiColor(_dti * 100))),
              Expanded(child: _ResultStat(label: 'Free Cash', value: formatINRCompact(_freeCash), color: FSColors.amountColor(_freeCash))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ResultStat(label: 'Debt Score', value: '$_score', color: _scoreColor)),
              Expanded(child: _ResultStat(label: 'Savings Rate', value: '${(_savingsRate * 100).toStringAsFixed(1)}%', color: _savingsRate >= 0.2 ? FSColors.positive : FSColors.warning)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _scoreColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: _scoreColor, width: 3)),
              ),
              child: Text(_verdict, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FSColors.textPrimary, height: 1.4)),
            ),
            const SizedBox(height: 16),
            Text('6-MONTH FORECAST', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: FSColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            FSBarChart(data: _forecastData, xKey: 'month', yKey: 'dti', colorFn: _dtiColor, height: 150),
          ]),
        ).animate(delay: 160.ms).fadeIn(),
        const SizedBox(height: 80),
      ]),
      bottomNavigationBar: const FSBottomNavBar(currentIndex: 4),
    );
  }

  void _calculateSkip() {
    final emi = double.tryParse(_emiInput.text) ?? 0;
    final rate = double.tryParse(_rateInput.text) ?? 0;
    if (emi <= 0 || rate <= 0) return;

    final monthlyRate = rate / 100 / 12;
    final penalty = emi * 0.02;
    final extraInterest = emi * monthlyRate * 2;
    final totalCost = penalty + extraInterest;

    setState(() {
      _skipResult = {
        'Penalty': '₹${penalty.toStringAsFixed(0)}',
        'Extra Interest': '₹${extraInterest.toStringAsFixed(0)}',
        'CIBIL Impact': '-15 to -40 points',
        'Total Cost': '₹${totalCost.toStringAsFixed(0)}',
      };
    });
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final void Function(double) onChanged;
  const _Slider({required this.label, required this.value, required this.min, required this.max, required this.step, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FSColors.textSecondary)),
        Text(formatINRCompact(value), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
      ]),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: ((max - min) / step).round(),
        onChanged: onChanged,
      ),
    ]);
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
    ]);
  }
}

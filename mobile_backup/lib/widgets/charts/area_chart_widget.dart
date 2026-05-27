import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';

class FSAreaChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;

  const FSAreaChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = FSColors.teal,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;

    return SizedBox(
      height: height,
      child: LineChart(LineChartData(
        minY: minY - range * 0.1,
        maxY: maxY + range * 0.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: FSColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(formatINRCompact(v), style: GoogleFonts.plusJakartaSans(fontSize: 9, color: FSColors.textTertiary)),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= labels.length || idx % 2 != 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[idx], style: GoogleFonts.plusJakartaSans(fontSize: 9, color: FSColors.textTertiary)),
              );
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withAlpha(60), color.withAlpha(0)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => FSColors.tertiary,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              formatINR(s.y),
              GoogleFonts.jetBrainsMono(fontSize: 12, color: FSColors.textPrimary),
            )).toList(),
          ),
        ),
      )),
    );
  }
}

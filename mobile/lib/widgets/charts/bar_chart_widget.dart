import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';

class FSBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xKey;
  final String yKey;
  final Color Function(double)? colorFn;
  final Color defaultColor;
  final double height;
  final bool showValues;

  const FSBarChart({
    super.key,
    required this.data,
    required this.xKey,
    required this.yKey,
    this.colorFn,
    this.defaultColor = FSColors.teal,
    this.height = 200,
    this.showValues = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    final maxY = data.map((e) => ((e[yKey] as num?)?.toDouble() ?? 0).abs()).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.25,
          minY: 0,
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
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${data[idx][xKey]}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9, color: FSColors.textTertiary),
                  ),
                );
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: data.asMap().entries.map((entry) {
            final idx = entry.key;
            final v = (entry.value[yKey] as num?)?.toDouble() ?? 0;
            final color = colorFn != null ? colorFn!(v) : (v >= 0 ? defaultColor : FSColors.negative);
            return BarChartGroupData(x: idx, barRods: [
              BarChartRodData(
                toY: v.abs(),
                color: color,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => FSColors.tertiary,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                formatINR(rod.toY),
                GoogleFonts.jetBrainsMono(fontSize: 12, color: FSColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

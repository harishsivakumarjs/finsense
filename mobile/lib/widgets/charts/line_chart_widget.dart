import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';

class FSLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xKey;
  final String yKey;
  final Color color;
  final double height;

  const FSLineChart({
    super.key,
    required this.data,
    required this.xKey,
    required this.yKey,
    this.color = FSColors.teal,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    final values = data.map((e) => (e[yKey] as num?)?.toDouble() ?? 0).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();

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
              if (idx < 0 || idx >= data.length || idx % 2 != 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${data[idx][xKey]}', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: FSColors.textTertiary)),
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
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
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

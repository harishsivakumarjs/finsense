import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';

class FSDonutChart extends StatefulWidget {
  final List<DonutSection> sections;
  final double size;
  final String? centerLabel;
  final double? centerValue;

  const FSDonutChart({
    super.key,
    required this.sections,
    this.size = 160,
    this.centerLabel,
    this.centerValue,
  });

  @override
  State<FSDonutChart> createState() => _FSDonutChartState();
}

class _FSDonutChartState extends State<FSDonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.sections.isEmpty) return SizedBox(width: widget.size, height: widget.size);
    final total = widget.sections.fold(0.0, (s, e) => s + e.value);

    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: PieChart(PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (_, resp) => setState(() {
                _touched = resp?.touchedSection?.touchedSectionIndex ?? -1;
              }),
            ),
            sections: widget.sections.asMap().entries.map((e) {
              final isTouched = e.key == _touched;
              final pct = total > 0 ? (e.value.value / total * 100) : 0;
              return PieChartSectionData(
                value: e.value.value,
                color: e.value.color,
                radius: isTouched ? 52 : 44,
                title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                titleStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              );
            }).toList(),
            centerSpaceRadius: widget.size * 0.25,
            sectionsSpace: 2,
          )),
        ),
        if (widget.centerLabel != null && widget.centerValue != null) ...[
          const SizedBox(height: 8),
          Text(widget.centerLabel!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textTertiary)),
          Text(formatINRCompact(widget.centerValue!), style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w500, color: FSColors.textPrimary)),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.sections.map((s) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(s.label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FSColors.textSecondary)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}

class DonutSection {
  final String label;
  final double value;
  final Color color;
  const DonutSection({required this.label, required this.value, required this.color});
}

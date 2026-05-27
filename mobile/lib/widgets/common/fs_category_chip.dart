import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/fs_color_scheme.dart';

class FSCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const FSCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    final color = selectedColor ?? c.teal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withAlpha(100) : c.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

class FSChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;
  final Map<String, Color>? colorMap;
  final Map<String, String>? labelMap;

  const FSChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.colorMap,
    this.labelMap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) => FSCategoryChip(
        label: labelMap?[opt] ?? opt,
        selected: selected == opt,
        onTap: () => onSelect(opt),
        selectedColor: colorMap?[opt],
      )).toList(),
    );
  }
}

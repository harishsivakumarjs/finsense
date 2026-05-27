import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class FSTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool isAmount;
  final int? maxLines;
  final String? hint;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final Widget? prefix;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const FSTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.isAmount = false,
    this.maxLines = 1,
    this.hint,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.prefix,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? (isAmount ? TextInputType.number : TextInputType.text),
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      focusNode: focusNode,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters ??
          (isAmount ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] : null),
      style: isAmount
          ? GoogleFonts.jetBrainsMono(fontSize: 16, color: FSColors.textPrimary)
          : GoogleFonts.plusJakartaSans(fontSize: 14, color: FSColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: isAmount ? '₹ ' : null,
        prefixStyle: GoogleFonts.jetBrainsMono(fontSize: 16, color: FSColors.textSecondary),
        suffixIcon: suffix,
        prefixIcon: prefix,
      ),
    );
  }
}

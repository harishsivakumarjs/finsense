import 'package:flutter/material.dart';
import '../../core/theme/fs_color_scheme.dart';

class FSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final Color? accentTop;
  final double? accentTopWidth;
  final VoidCallback? onTap;

  const FSCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = 16,
    this.accentTop,
    this.accentTopWidth = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fsc;
    Widget content = Container(
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.border),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }
    return content;
  }
}

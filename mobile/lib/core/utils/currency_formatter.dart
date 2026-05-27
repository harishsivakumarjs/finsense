import 'package:flutter/material.dart';
import '../constants/colors.dart';

String formatINR(double amount) {
  final isNegative = amount < 0;
  final abs = amount.abs();
  final intPart = abs.truncate();
  final decPart = ((abs - intPart) * 100).round();

  final str = intPart.toString();
  final result = StringBuffer();

  if (str.length <= 3) {
    result.write(str);
  } else {
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    result.write(buf);
    result.write(',');
    result.write(last3);
  }

  final formatted = decPart > 0
      ? '₹${result}.${decPart.toString().padLeft(2, '0')}'
      : '₹$result';

  return isNegative ? '-$formatted' : formatted;
}

String formatINRCompact(double amount) {
  final isNegative = amount < 0;
  final abs = amount.abs();
  String formatted;
  if (abs >= 1e7) {
    formatted = '₹${(abs / 1e7).toStringAsFixed(2)}Cr';
  } else if (abs >= 1e5) {
    formatted = '₹${(abs / 1e5).toStringAsFixed(2)}L';
  } else if (abs >= 1e3) {
    formatted = '₹${(abs / 1e3).toStringAsFixed(1)}K';
  } else {
    formatted = '₹${abs.toStringAsFixed(0)}';
  }
  return isNegative ? '-$formatted' : formatted;
}

Color amountColor(double amount) => FSColors.amountColor(amount);

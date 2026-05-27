import 'package:intl/intl.dart';

String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

String formatMonthYear(DateTime d) => DateFormat('MMM yyyy').format(d);

String timeAgo(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inDays >= 365) {
    final years = (diff.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
  if (diff.inDays >= 30) {
    final months = (diff.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  }
  if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
  return 'just now';
}

String financialYear(DateTime d) {
  if (d.month >= 4) {
    return '${d.year}-${(d.year + 1).toString().substring(2)}';
  } else {
    return '${d.year - 1}-${d.year.toString().substring(2)}';
  }
}

String currentFY() => financialYear(DateTime.now());

int fyStartYear(DateTime d) => d.month >= 4 ? d.year : d.year - 1;

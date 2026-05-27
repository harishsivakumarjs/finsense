double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

class IncomeModel {
  final String id;
  final double amount;
  final String sourceType;
  final String description;
  final String receivedOn;
  final String? taxCategory;

  const IncomeModel({
    required this.id,
    required this.amount,
    required this.sourceType,
    required this.description,
    required this.receivedOn,
    this.taxCategory,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> j) => IncomeModel(
        id: _toStr(j['id']),
        amount: _toDouble(j['amount']),
        sourceType: j['source_type'] as String? ?? 'other',
        description: j['description'] as String? ?? '',
        receivedOn: j['received_on'] as String? ?? '',
        taxCategory: j['tax_category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'source_type': sourceType,
        'description': description,
        'received_on': receivedOn,
        if (taxCategory != null) 'tax_category': taxCategory,
      };
}

const incomeSourceLabels = {
  'salary': 'Salary',
  'pocket_money': 'Pocket Money',
  'freelance': 'Freelance',
  'youtube': 'YouTube',
  'trading': 'Trading',
  'investment': 'Investment',
  'other': 'Other',
};

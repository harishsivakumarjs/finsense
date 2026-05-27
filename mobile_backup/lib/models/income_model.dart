class IncomeModel {
  final int id;
  final double amount;
  final String source;
  final String description;
  final String date;
  final String? taxCategory;

  const IncomeModel({
    required this.id,
    required this.amount,
    required this.source,
    required this.description,
    required this.date,
    this.taxCategory,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> j) => IncomeModel(
        id: j['id'] as int,
        amount: (j['amount'] as num).toDouble(),
        source: j['source'] as String? ?? 'other',
        description: j['description'] as String? ?? '',
        date: j['date'] as String? ?? '',
        taxCategory: j['tax_category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'source': source,
        'description': description,
        'date': date,
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

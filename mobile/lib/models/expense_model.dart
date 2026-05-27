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

class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String spentOn;
  final bool isRecurring;
  final bool isCreatorExpense;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.spentOn,
    this.isRecurring = false,
    this.isCreatorExpense = false,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) => ExpenseModel(
        id: _toStr(j['id']),
        amount: _toDouble(j['amount']),
        category: j['category'] as String? ?? 'other',
        description: j['description'] as String? ?? '',
        spentOn: j['spent_on'] as String? ?? '',
        isRecurring: j['is_recurring'] as bool? ?? false,
        isCreatorExpense: j['is_creator_expense'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'category': category,
        'description': description,
        'spent_on': spentOn,
        'is_recurring': isRecurring,
        'is_creator_expense': isCreatorExpense,
      };
}

const expenseCategoryLabels = {
  'food': 'Food',
  'transport': 'Transport',
  'bills': 'Bills',
  'health': 'Health',
  'entertainment': 'Entertainment',
  'shopping': 'Shopping',
  'subscriptions': 'Subscriptions',
  'education': 'Education',
  'other': 'Other',
};

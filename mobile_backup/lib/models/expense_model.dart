class ExpenseModel {
  final int id;
  final double amount;
  final String category;
  final String description;
  final String date;
  final bool isRecurring;
  final bool isCreatorExpense;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.isRecurring = false,
    this.isCreatorExpense = false,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) => ExpenseModel(
        id: j['id'] as int,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String? ?? 'other',
        description: j['description'] as String? ?? '',
        date: j['date'] as String? ?? '',
        isRecurring: j['is_recurring'] as bool? ?? false,
        isCreatorExpense: j['is_creator_expense'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
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

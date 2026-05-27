double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class DashboardModel {
  final double netWorth;
  final double netWorthChange;
  final double totalIncome;
  final double totalExpenses;
  final double freeCash;
  final double debtScore;
  final double taxDue;
  final List<DashboardActivity> recentActivity;
  final List<DtiPoint> dtiHistory;
  final String? alertMessage;

  const DashboardModel({
    required this.netWorth,
    required this.netWorthChange,
    required this.totalIncome,
    required this.totalExpenses,
    required this.freeCash,
    required this.debtScore,
    required this.taxDue,
    required this.recentActivity,
    required this.dtiHistory,
    this.alertMessage,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> j) => DashboardModel(
        netWorth: _toDouble(j['net_worth']),
        netWorthChange: _toDouble(j['net_worth_change']),
        totalIncome: _toDouble(j['total_income']),
        totalExpenses: _toDouble(j['total_expenses']),
        freeCash: _toDouble(j['free_cash']),
        debtScore: _toDouble(j['debt_score']),
        taxDue: _toDouble(j['tax_due']),
        recentActivity: (j['recent_activity'] as List? ?? [])
            .map((e) => DashboardActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
        dtiHistory: (j['dti_history'] as List? ?? [])
            .map((e) => DtiPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        alertMessage: j['alert_message'] as String?,
      );
}

class DashboardActivity {
  final String? id;
  final String type;
  final String description;
  final double amount;
  final String date;
  final String? category;

  const DashboardActivity({
    this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> j) => DashboardActivity(
        id: j['id']?.toString(),
        type: j['type'] as String? ?? '',
        description: j['description'] as String? ?? '',
        amount: _toDouble(j['amount']),
        date: j['date'] as String? ?? '',
        category: j['category'] as String?,
      );
}

class DtiPoint {
  final String month;
  final double dti;

  const DtiPoint({required this.month, required this.dti});

  factory DtiPoint.fromJson(Map<String, dynamic> j) => DtiPoint(
        month: j['month'] as String? ?? '',
        dti: _toDouble(j['dti']),
      );
}

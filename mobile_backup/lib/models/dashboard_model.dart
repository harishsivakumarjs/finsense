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
        netWorth: (j['net_worth'] as num?)?.toDouble() ?? 0,
        netWorthChange: (j['net_worth_change'] as num?)?.toDouble() ?? 0,
        totalIncome: (j['total_income'] as num?)?.toDouble() ?? 0,
        totalExpenses: (j['total_expenses'] as num?)?.toDouble() ?? 0,
        freeCash: (j['free_cash'] as num?)?.toDouble() ?? 0,
        debtScore: (j['debt_score'] as num?)?.toDouble() ?? 0,
        taxDue: (j['tax_due'] as num?)?.toDouble() ?? 0,
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
  final String type;
  final String description;
  final double amount;
  final String date;
  final String? category;

  const DashboardActivity({
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> j) => DashboardActivity(
        type: j['type'] as String? ?? '',
        description: j['description'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
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
        dti: (j['dti'] as num?)?.toDouble() ?? 0,
      );
}

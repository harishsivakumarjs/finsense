class LoanModel {
  final int id;
  final String loanType;
  final String loanName;
  final String bankName;
  final double principalAmount;
  final double emiAmount;
  final double interestRate;
  final String startDate;
  final int totalMonths;
  final int monthsPaid;
  final double outstandingBalance;
  final bool isActive;

  const LoanModel({
    required this.id,
    required this.loanType,
    required this.loanName,
    required this.bankName,
    required this.principalAmount,
    required this.emiAmount,
    required this.interestRate,
    required this.startDate,
    required this.totalMonths,
    required this.monthsPaid,
    required this.outstandingBalance,
    required this.isActive,
  });

  factory LoanModel.fromJson(Map<String, dynamic> j) => LoanModel(
        id: j['id'] as int,
        loanType: j['loan_type'] as String? ?? 'personal',
        loanName: j['loan_name'] as String? ?? '',
        bankName: j['bank_name'] as String? ?? '',
        principalAmount: (j['principal_amount'] as num?)?.toDouble() ?? 0,
        emiAmount: (j['emi_amount'] as num?)?.toDouble() ?? 0,
        interestRate: (j['interest_rate'] as num?)?.toDouble() ?? 0,
        startDate: j['start_date'] as String? ?? '',
        totalMonths: j['total_months'] as int? ?? 0,
        monthsPaid: j['months_paid'] as int? ?? 0,
        outstandingBalance: (j['outstanding_balance'] as num?)?.toDouble() ?? 0,
        isActive: j['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'loan_type': loanType,
        'loan_name': loanName,
        'bank_name': bankName,
        'principal_amount': principalAmount,
        'emi_amount': emiAmount,
        'interest_rate': interestRate,
        'start_date': startDate,
        'total_months': totalMonths,
        'is_active': isActive,
      };

  double get progressFraction =>
      totalMonths > 0 ? (monthsPaid / totalMonths).clamp(0.0, 1.0) : 0;
}

class CreditCardModel {
  final int id;
  final String cardName;
  final String bankName;
  final double creditLimit;
  final double outstanding;
  final double minimumDue;
  final int dueDate;
  final int statementDate;

  const CreditCardModel({
    required this.id,
    required this.cardName,
    required this.bankName,
    required this.creditLimit,
    required this.outstanding,
    required this.minimumDue,
    required this.dueDate,
    required this.statementDate,
  });

  factory CreditCardModel.fromJson(Map<String, dynamic> j) => CreditCardModel(
        id: j['id'] as int,
        cardName: j['card_name'] as String? ?? '',
        bankName: j['bank_name'] as String? ?? '',
        creditLimit: (j['credit_limit'] as num?)?.toDouble() ?? 0,
        outstanding: (j['outstanding'] as num?)?.toDouble() ?? 0,
        minimumDue: (j['minimum_due'] as num?)?.toDouble() ?? 0,
        dueDate: j['due_date'] as int? ?? 1,
        statementDate: j['statement_date'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'card_name': cardName,
        'bank_name': bankName,
        'credit_limit': creditLimit,
        'outstanding': outstanding,
        'minimum_due': minimumDue,
        'due_date': dueDate,
        'statement_date': statementDate,
      };

  double get utilisation =>
      creditLimit > 0 ? (outstanding / creditLimit).clamp(0.0, 1.0) : 0;
}

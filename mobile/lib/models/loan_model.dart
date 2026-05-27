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

class LoanModel {
  final String id;
  final String loanType;
  final String loanName;
  final String bankName;
  final double principal;
  final double emiAmount;
  final double interestRate;
  final String startDate;
  final int monthsTotal;
  final bool isActive;

  const LoanModel({
    required this.id,
    required this.loanType,
    required this.loanName,
    required this.bankName,
    required this.principal,
    required this.emiAmount,
    required this.interestRate,
    required this.startDate,
    required this.monthsTotal,
    required this.isActive,
  });

  factory LoanModel.fromJson(Map<String, dynamic> j) => LoanModel(
        id: _toStr(j['id']),
        loanType: j['loan_type'] as String? ?? 'personal',
        loanName: j['loan_name'] as String? ?? '',
        bankName: j['bank_name'] as String? ?? '',
        principal: _toDouble(j['principal']),
        emiAmount: _toDouble(j['emi_amount']),
        interestRate: _toDouble(j['interest_rate']),
        startDate: j['start_date'] as String? ?? '',
        monthsTotal: _toInt(j['months_total']),
        isActive: j['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'loan_type': loanType,
        'loan_name': loanName,
        'bank_name': bankName,
        'principal': principal,
        'emi_amount': emiAmount,
        'interest_rate': interestRate,
        'start_date': startDate,
        'months_total': monthsTotal,
        'is_active': isActive,
      };
}

class CreditCardModel {
  final String id;
  final String cardName;
  final String bankName;
  final double creditLimit;
  final double outstanding;
  final double minimumDue;
  final int? dueDate;
  final int? statementDate;

  const CreditCardModel({
    required this.id,
    required this.cardName,
    required this.bankName,
    required this.creditLimit,
    required this.outstanding,
    required this.minimumDue,
    this.dueDate,
    this.statementDate,
  });

  factory CreditCardModel.fromJson(Map<String, dynamic> j) => CreditCardModel(
        id: _toStr(j['id']),
        cardName: j['card_name'] as String? ?? '',
        bankName: j['bank_name'] as String? ?? '',
        creditLimit: _toDouble(j['credit_limit']),
        outstanding: _toDouble(j['outstanding']),
        minimumDue: _toDouble(j['minimum_due']),
        dueDate: j['due_date'] != null ? _toInt(j['due_date']) : null,
        statementDate: j['statement_date'] != null ? _toInt(j['statement_date']) : null,
      );

  Map<String, dynamic> toJson() => {
        'card_name': cardName,
        'bank_name': bankName,
        'credit_limit': creditLimit,
        'outstanding': outstanding,
        'minimum_due': minimumDue,
        if (dueDate != null) 'due_date': dueDate,
        if (statementDate != null) 'statement_date': statementDate,
      };

  double get utilisation =>
      creditLimit > 0 ? (outstanding / creditLimit).clamp(0.0, 1.0) : 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

class TaxModel {
  final double estimatedDue;
  final double paid;
  final double netPayable;
  final List<TaxIncomeHead> incomeHeads;
  final TaxDeductions deductions;
  final List<AdvanceTaxPayment> advanceTax;
  final List<TaxSuggestion> suggestions;

  const TaxModel({
    required this.estimatedDue,
    required this.paid,
    required this.netPayable,
    required this.incomeHeads,
    required this.deductions,
    required this.advanceTax,
    required this.suggestions,
  });

  factory TaxModel.fromJson(Map<String, dynamic> j) => TaxModel(
        estimatedDue: _toDouble(j['estimated_due']),
        paid: _toDouble(j['paid']),
        netPayable: _toDouble(j['net_payable']),
        incomeHeads: (j['income_heads'] as List? ?? [])
            .map((e) => TaxIncomeHead.fromJson(e as Map<String, dynamic>))
            .toList(),
        deductions: TaxDeductions.fromJson(j['deductions'] as Map<String, dynamic>? ?? {}),
        advanceTax: (j['advance_tax'] as List? ?? [])
            .map((e) => AdvanceTaxPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggestions: (j['suggestions'] as List? ?? [])
            .map((e) => TaxSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TaxIncomeHead {
  final String head;
  final double gross;
  final double rate;
  final double tax;

  const TaxIncomeHead({required this.head, required this.gross, required this.rate, required this.tax});

  factory TaxIncomeHead.fromJson(Map<String, dynamic> j) => TaxIncomeHead(
        head: j['head'] as String? ?? '',
        gross: _toDouble(j['gross']),
        rate: _toDouble(j['rate']),
        tax: _toDouble(j['tax']),
      );
}

class TaxDeductions {
  final double section80C;
  final double section80D;
  final double section80CCD;

  const TaxDeductions({required this.section80C, required this.section80D, required this.section80CCD});

  factory TaxDeductions.fromJson(Map<String, dynamic> j) => TaxDeductions(
        section80C: _toDouble(j['80C']),
        section80D: _toDouble(j['80D']),
        section80CCD: _toDouble(j['80CCD']),
      );
}

class AdvanceTaxPayment {
  final String id;
  final String deadline;
  final double amountDue;
  final bool isPaid;
  final String? paidDate;

  const AdvanceTaxPayment({
    required this.id,
    required this.deadline,
    required this.amountDue,
    required this.isPaid,
    this.paidDate,
  });

  factory AdvanceTaxPayment.fromJson(Map<String, dynamic> j) => AdvanceTaxPayment(
        id: _toStr(j['id']),
        deadline: j['deadline'] as String? ?? '',
        amountDue: _toDouble(j['amount_due']),
        isPaid: j['is_paid'] as bool? ?? false,
        paidDate: j['paid_date'] as String?,
      );

  int get daysRemaining {
    final d = DateTime.tryParse(deadline);
    if (d == null) return 0;
    return d.difference(DateTime.now()).inDays;
  }
}

class TaxSuggestion {
  final String title;
  final String action;
  final double potentialSaving;

  const TaxSuggestion({required this.title, required this.action, required this.potentialSaving});

  factory TaxSuggestion.fromJson(Map<String, dynamic> j) => TaxSuggestion(
        title: j['title'] as String? ?? '',
        action: j['action'] as String? ?? '',
        potentialSaving: _toDouble(j['potential_saving']),
      );
}

class TaxDeductionEntry {
  final String id;
  final String section;
  final String description;
  final double amount;

  const TaxDeductionEntry({required this.id, required this.section, required this.description, required this.amount});

  factory TaxDeductionEntry.fromJson(Map<String, dynamic> j) => TaxDeductionEntry(
        id: _toStr(j['id']),
        section: j['section'] as String? ?? '',
        description: j['description'] as String? ?? '',
        amount: _toDouble(j['amount']),
      );
}

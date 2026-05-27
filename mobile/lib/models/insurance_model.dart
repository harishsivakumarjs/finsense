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

class InsuranceModel {
  final String id;
  final String policyType;
  final String policyName;
  final String insurerName;
  final String? policyNumber;
  final double sumAssured;
  final double annualPremium;
  final String premiumFrequency;
  final String nextDueDate;
  final String startDate;
  final String? endDate;
  final String taxSection;
  final double taxBenefitAmount;
  final bool isActive;
  final String? notes;

  const InsuranceModel({
    required this.id,
    required this.policyType,
    required this.policyName,
    required this.insurerName,
    this.policyNumber,
    required this.sumAssured,
    required this.annualPremium,
    required this.premiumFrequency,
    required this.nextDueDate,
    required this.startDate,
    this.endDate,
    required this.taxSection,
    required this.taxBenefitAmount,
    required this.isActive,
    this.notes,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> j) => InsuranceModel(
        id: _toStr(j['id']),
        policyType: j['policy_type'] as String? ?? 'other',
        policyName: j['policy_name'] as String? ?? '',
        insurerName: j['insurer_name'] as String? ?? '',
        policyNumber: j['policy_number'] as String?,
        sumAssured: _toDouble(j['sum_assured']),
        annualPremium: _toDouble(j['annual_premium']),
        premiumFrequency: j['premium_frequency'] as String? ?? 'yearly',
        nextDueDate: j['next_due_date'] as String? ?? '',
        startDate: j['start_date'] as String? ?? '',
        endDate: j['end_date'] as String?,
        taxSection: j['tax_section'] as String? ?? 'none',
        taxBenefitAmount: _toDouble(j['tax_benefit_amount']),
        isActive: j['is_active'] as bool? ?? true,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'policy_type': policyType,
        'policy_name': policyName,
        'insurer_name': insurerName,
        if (policyNumber != null) 'policy_number': policyNumber,
        'sum_assured': sumAssured,
        'annual_premium': annualPremium,
        'premium_frequency': premiumFrequency,
        'next_due_date': nextDueDate,
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        'tax_section': taxSection,
        'tax_benefit_amount': taxBenefitAmount,
        'is_active': isActive,
        if (notes != null) 'notes': notes,
      };

  int get daysUntilDue {
    final due = DateTime.tryParse(nextDueDate);
    if (due == null) return 999;
    return due.difference(DateTime.now()).inDays;
  }
}

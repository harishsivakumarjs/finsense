class InvestmentModel {
  final int id;
  final String assetType;
  final String name;
  final double investedAmount;
  final double currentValue;
  final String purchaseDate;
  final double quantity;
  final String unit;
  final String? taxSection;
  final String? maturityDate;
  final String? notes;

  const InvestmentModel({
    required this.id,
    required this.assetType,
    required this.name,
    required this.investedAmount,
    required this.currentValue,
    required this.purchaseDate,
    required this.quantity,
    required this.unit,
    this.taxSection,
    this.maturityDate,
    this.notes,
  });

  factory InvestmentModel.fromJson(Map<String, dynamic> j) => InvestmentModel(
        id: j['id'] as int,
        assetType: j['asset_type'] as String? ?? 'other',
        name: j['name'] as String? ?? '',
        investedAmount: (j['invested_amount'] as num?)?.toDouble() ?? 0,
        currentValue: (j['current_value'] as num?)?.toDouble() ?? 0,
        purchaseDate: j['purchase_date'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 1,
        unit: j['unit'] as String? ?? 'units',
        taxSection: j['tax_section'] as String?,
        maturityDate: j['maturity_date'] as String?,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'asset_type': assetType,
        'name': name,
        'invested_amount': investedAmount,
        'current_value': currentValue,
        'purchase_date': purchaseDate,
        'quantity': quantity,
        'unit': unit,
        if (taxSection != null) 'tax_section': taxSection,
        if (maturityDate != null) 'maturity_date': maturityDate,
        if (notes != null) 'notes': notes,
      };

  double get gainLoss => currentValue - investedAmount;
  double get gainLossPct =>
      investedAmount > 0 ? (gainLoss / investedAmount * 100) : 0;

  int get daysHeld {
    final purchase = DateTime.tryParse(purchaseDate);
    if (purchase == null) return 0;
    return DateTime.now().difference(purchase).inDays;
  }

  bool get isLtcg {
    final threshold = ['stocks', 'mutual_fund'].contains(assetType) ? 365 : 730;
    return daysHeld >= threshold;
  }
}

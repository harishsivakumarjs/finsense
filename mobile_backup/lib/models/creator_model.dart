class CreatorModel {
  final int id;
  final String incomeType;
  final double amount;
  final String? brandName;
  final String? videoTitle;
  final String date;
  final double? rpm;
  final String? notes;

  const CreatorModel({
    required this.id,
    required this.incomeType,
    required this.amount,
    this.brandName,
    this.videoTitle,
    required this.date,
    this.rpm,
    this.notes,
  });

  factory CreatorModel.fromJson(Map<String, dynamic> j) => CreatorModel(
        id: j['id'] as int,
        incomeType: j['income_type'] as String? ?? 'other',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        brandName: j['brand_name'] as String?,
        videoTitle: j['video_title'] as String?,
        date: j['date'] as String? ?? '',
        rpm: (j['rpm'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'income_type': incomeType,
        'amount': amount,
        if (brandName != null) 'brand_name': brandName,
        if (videoTitle != null) 'video_title': videoTitle,
        'date': date,
        if (rpm != null) 'rpm': rpm,
        if (notes != null) 'notes': notes,
      };
}

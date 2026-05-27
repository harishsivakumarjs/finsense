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

class CreatorModel {
  final String id;
  final String incomeType;
  final double amount;
  final String? brandName;
  final String? videoTitle;
  final String receivedOn;
  final double? rpm;
  final String? notes;

  const CreatorModel({
    required this.id,
    required this.incomeType,
    required this.amount,
    this.brandName,
    this.videoTitle,
    required this.receivedOn,
    this.rpm,
    this.notes,
  });

  factory CreatorModel.fromJson(Map<String, dynamic> j) => CreatorModel(
        id: _toStr(j['id']),
        incomeType: j['income_type'] as String? ?? 'other',
        amount: _toDouble(j['amount']),
        brandName: j['brand_name'] as String?,
        videoTitle: j['video_title'] as String?,
        receivedOn: j['received_on'] as String? ?? '',
        rpm: j['rpm'] != null ? _toDouble(j['rpm']) : null,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'income_type': incomeType,
        'amount': amount,
        if (brandName != null) 'brand_name': brandName,
        if (videoTitle != null) 'video_title': videoTitle,
        'received_on': receivedOn,
        if (rpm != null) 'rpm': rpm,
        if (notes != null) 'notes': notes,
      };
}

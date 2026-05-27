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

class TradeModel {
  final String id;
  final String scrip;
  final String tradeType;
  final double buyPrice;
  final double? sellPrice;
  final double quantity;
  final double charges;
  final String buyDate;
  final String? sellDate;
  final double? netPnl;
  final String? notes;

  const TradeModel({
    required this.id,
    required this.scrip,
    required this.tradeType,
    required this.buyPrice,
    this.sellPrice,
    required this.quantity,
    required this.charges,
    required this.buyDate,
    this.sellDate,
    this.netPnl,
    this.notes,
  });

  factory TradeModel.fromJson(Map<String, dynamic> j) => TradeModel(
        id: _toStr(j['id']),
        scrip: j['scrip'] as String? ?? '',
        tradeType: j['trade_type'] as String? ?? 'delivery',
        buyPrice: _toDouble(j['buy_price']),
        sellPrice: j['sell_price'] != null ? _toDouble(j['sell_price']) : null,
        quantity: _toDouble(j['quantity']),
        charges: _toDouble(j['charges']),
        buyDate: j['buy_date'] as String? ?? '',
        sellDate: j['sell_date'] as String?,
        netPnl: j['net_pnl'] != null ? _toDouble(j['net_pnl']) : null,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'scrip': scrip,
        'trade_type': tradeType,
        'buy_price': buyPrice,
        if (sellPrice != null) 'sell_price': sellPrice,
        'quantity': quantity,
        'charges': charges,
        'buy_date': buyDate,
        if (sellDate != null) 'sell_date': sellDate,
        if (notes != null) 'notes': notes,
      };

  bool get isClosed => sellPrice != null && sellDate != null;

  double get computedPnl {
    if (sellPrice == null) return 0;
    return (sellPrice! - buyPrice) * quantity - charges;
  }
}

class TradeModel {
  final int id;
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
        id: j['id'] as int,
        scrip: j['scrip'] as String? ?? '',
        tradeType: j['trade_type'] as String? ?? 'delivery',
        buyPrice: (j['buy_price'] as num?)?.toDouble() ?? 0,
        sellPrice: (j['sell_price'] as num?)?.toDouble(),
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        charges: (j['charges'] as num?)?.toDouble() ?? 0,
        buyDate: j['buy_date'] as String? ?? '',
        sellDate: j['sell_date'] as String?,
        netPnl: (j['net_pnl'] as num?)?.toDouble(),
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

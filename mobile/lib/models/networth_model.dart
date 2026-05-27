double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class NetworthModel {
  final double totalNetWorth;
  final double totalAssets;
  final double totalLiabilities;
  final double changeThisMonth;
  final List<NetworthAsset> assets;
  final List<NetworthLiability> liabilities;
  final List<NetworthHistoryPoint> history;

  const NetworthModel({
    required this.totalNetWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.changeThisMonth,
    required this.assets,
    required this.liabilities,
    required this.history,
  });

  factory NetworthModel.fromJson(Map<String, dynamic> j) => NetworthModel(
        totalNetWorth: _toDouble(j['total_net_worth']),
        totalAssets: _toDouble(j['total_assets']),
        totalLiabilities: _toDouble(j['total_liabilities']),
        changeThisMonth: _toDouble(j['change_this_month']),
        assets: (j['assets'] as List? ?? [])
            .map((e) => NetworthAsset.fromJson(e as Map<String, dynamic>))
            .toList(),
        liabilities: (j['liabilities'] as List? ?? [])
            .map((e) => NetworthLiability.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: (j['history'] as List? ?? [])
            .map((e) => NetworthHistoryPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NetworthAsset {
  final String name;
  final double value;
  final String category;

  const NetworthAsset({required this.name, required this.value, required this.category});

  factory NetworthAsset.fromJson(Map<String, dynamic> j) => NetworthAsset(
        name: j['name'] as String? ?? '',
        value: _toDouble(j['value']),
        category: j['category'] as String? ?? '',
      );
}

class NetworthLiability {
  final String name;
  final double value;
  final String category;

  const NetworthLiability({required this.name, required this.value, required this.category});

  factory NetworthLiability.fromJson(Map<String, dynamic> j) => NetworthLiability(
        name: j['name'] as String? ?? '',
        value: _toDouble(j['value']),
        category: j['category'] as String? ?? '',
      );
}

class NetworthHistoryPoint {
  final String month;
  final double netWorth;

  const NetworthHistoryPoint({required this.month, required this.netWorth});

  factory NetworthHistoryPoint.fromJson(Map<String, dynamic> j) => NetworthHistoryPoint(
        month: j['month'] as String? ?? '',
        netWorth: _toDouble(j['net_worth']),
      );
}

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
        totalNetWorth: (j['total_net_worth'] as num?)?.toDouble() ?? 0,
        totalAssets: (j['total_assets'] as num?)?.toDouble() ?? 0,
        totalLiabilities: (j['total_liabilities'] as num?)?.toDouble() ?? 0,
        changeThisMonth: (j['change_this_month'] as num?)?.toDouble() ?? 0,
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
        value: (j['value'] as num?)?.toDouble() ?? 0,
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
        value: (j['value'] as num?)?.toDouble() ?? 0,
        category: j['category'] as String? ?? '',
      );
}

class NetworthHistoryPoint {
  final String month;
  final double netWorth;

  const NetworthHistoryPoint({required this.month, required this.netWorth});

  factory NetworthHistoryPoint.fromJson(Map<String, dynamic> j) => NetworthHistoryPoint(
        month: j['month'] as String? ?? '',
        netWorth: (j['net_worth'] as num?)?.toDouble() ?? 0,
      );
}

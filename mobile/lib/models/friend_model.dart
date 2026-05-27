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

class FriendModel {
  final String id;
  final String friendName;
  final double amount;
  final String reason;
  final String date;
  final bool isSettled;

  const FriendModel({
    required this.id,
    required this.friendName,
    required this.amount,
    required this.reason,
    required this.date,
    required this.isSettled,
  });

  factory FriendModel.fromJson(Map<String, dynamic> j) => FriendModel(
        id: _toStr(j['id']),
        friendName: j['friend_name'] as String? ?? '',
        amount: _toDouble(j['amount']),
        reason: j['reason'] as String? ?? '',
        date: j['date'] as String? ?? '',
        isSettled: j['is_settled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'friend_name': friendName,
        'amount': amount,
        'reason': reason,
        'date': date,
        'is_settled': isSettled,
      };

  // amount > 0 = they owe you, amount < 0 = you owe them
  bool get theyOweMe => amount > 0;
  String get initials {
    final parts = friendName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return friendName.isNotEmpty ? friendName[0].toUpperCase() : 'F';
  }
}

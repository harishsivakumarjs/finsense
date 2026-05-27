class FriendModel {
  final int id;
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
        id: j['id'] as int,
        friendName: j['friend_name'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
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

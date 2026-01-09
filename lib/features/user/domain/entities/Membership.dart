class Membership {
  final String type; // 'free' | 'premium'
  final DateTime startedAt;
  final DateTime expiresAt;

  const Membership({
    required this.type,
    required this.startedAt,
    required this.expiresAt,
  }) : assert(type == 'free' || type == 'premium');

  factory Membership.free() {
    final now = DateTime.now();
    return Membership(type: 'free', startedAt: now, expiresAt: now);
  }

  factory Membership.premium() {
    final now = DateTime.now();
    final expires = DateTime(now.year + 1, now.month, now.day, now.hour, now.minute, now.second);
    return Membership(type: 'premium', startedAt: now, expiresAt: expires);
  }

  bool get isPremium => type == 'premium';

  bool get isEnabled {
    final now = DateTime.now();
    return now.isAfter(startedAt) && now.isBefore(expiresAt);
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      type: json['type'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Membership copyWith({
    String? type,
    DateTime? startedAt,
    DateTime? expiresAt,
  }) {
    return Membership(
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
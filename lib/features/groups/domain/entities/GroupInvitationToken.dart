class GroupInvitationToken {
  final String token;
  final DateTime expiresAt;
  final DateTime? createdAt;

  const GroupInvitationToken({
    required this.token,
    required this.expiresAt,
    this.createdAt,
  });

  bool isExpired({DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.isAfter(expiresAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory GroupInvitationToken.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expiresAt'] ?? json['expires_at'];
    return GroupInvitationToken(
      token: json['token'] as String? ?? '',
      expiresAt: expiresRaw is String
          ? DateTime.parse(expiresRaw)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null),
    );
  }
}

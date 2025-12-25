import 'Membership.dart';

class User {
  final String id;
  final String userName;
  final String name;
  final String email;
  final String hashedPassword;
  final String userType; // e.g. 'admin' | 'player'
  final String avatarUrl;
  final String theme; // 'light' | 'dark'
  final String language; // 'es' | 'en' | ...
  final int gameStreak;
  final Membership membership;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.userName,
    required this.name,
    required this.email,
    this.hashedPassword = '',
    required this.userType,
    required this.avatarUrl,
    required this.theme,
    required this.language,
    required this.gameStreak,
    required this.membership,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPremiumMembershipEnabled =>
      membership.isPremium && membership.isEnabled;

  User enablePremiumMembership() {
    final now = DateTime.now();
    return copyWith(membership: Membership.premium(), updatedAt: now);
  }

  User enableFreeMembership() {
    final now = DateTime.now();
    return copyWith(membership: Membership.free(), updatedAt: now);
  }

  User copyWith({
    String? id,
    String? userName,
    String? name,
    String? email,
    String? hashedPassword,
    String? userType,
    String? avatarUrl,
    String? theme,
    String? language,
    int? gameStreak,
    Membership? membership,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      name: name ?? this.name,
      email: email ?? this.email,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      userType: userType ?? this.userType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      gameStreak: gameStreak ?? this.gameStreak,
      membership: membership ?? this.membership,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'name': name,
        'email': email,
      if (hashedPassword.isNotEmpty) 'hashedPassword': hashedPassword,
        'userType': userType,
        'avatarUrl': avatarUrl,
        'theme': theme,
        'language': language,
        'gameStreak': gameStreak,
        'membership': membership.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      userName: json['userName'] as String,
      name: (json['name'] ?? '') as String,
      email: json['email'] as String,
      hashedPassword: (json['hashedPassword'] ?? '') as String,
      userType: json['userType'] as String,
      avatarUrl: (json['avatarUrl'] ?? '') as String,
      theme: (json['theme'] ?? 'light') as String,
      language: (json['language'] ?? 'es') as String,
      gameStreak: (json['gameStreak'] ?? 0) as int,
      membership: Membership.fromJson(json['membership'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
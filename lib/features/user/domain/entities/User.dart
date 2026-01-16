import 'Membership.dart';

class User {
  final String id;
  final String userName;
  final String name;
  final String description;
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
    this.description = '',
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
    String? description,
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
      description: description ?? this.description,
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
      if (description.isNotEmpty) 'description': description,
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
    // Soporta respuestas anidadas { user: { ... } } y nombres alternativos de campos.
    final Map<String, dynamic> src =
        (json['user'] is Map<String, dynamic>) ? Map<String, dynamic>.from(json['user']) : json;

    final dynamic rawHash = src['hashedPassword'] ??
        src['password'] ??
        src['pwd'] ??
        src['pass'] ??
        src['passwordHash'] ??
        src['password_hash'] ??
        src['hashed_password'] ??
        src['hashPassword'] ??
        src['hash_password'];
    final hashed = rawHash == null ? '' : rawHash.toString();

    final profile = (src['userProfileDetails'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(src['userProfileDetails'])
        : const <String, dynamic>{};
    final preferences = (src['preferences'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(src['preferences'])
        : const <String, dynamic>{};

    final String id = (src['id'] ?? '').toString();
    final String userName = (src['userName'] ?? src['username'] ?? '').toString();
    final String email = (src['email'] ?? '').toString();
    final String userType = (src['userType'] ?? src['type'] ?? 'student').toString();
    final String themeRaw = (preferences['theme'] ?? src['theme'] ?? 'light').toString();
    final String theme = themeRaw.toLowerCase() == 'dark' ? 'dark' : (themeRaw.toUpperCase() == 'DARK' ? 'dark' : 'light');
    final String name = (profile['name'] ?? src['name'] ?? '').toString();
    final String description = (profile['description'] ?? src['description'] ?? '').toString();
    final String avatarUrl = (profile['avatarAssetUrl'] ?? src['avatarUrl'] ?? '').toString();
    final bool isPremium = (src['isPremium'] == true);

    final Membership membership = isPremium ? Membership.premium() : Membership.free();

    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = DateTime.parse((src['createdAt'] ?? DateTime.now().toIso8601String()).toString());
    } catch (_) {
      createdAt = DateTime.now();
    }
    try {
      updatedAt = DateTime.parse((src['updatedAt'] ?? DateTime.now().toIso8601String()).toString());
    } catch (_) {
      updatedAt = DateTime.now();
    }

    return User(
      id: id,
      userName: userName,
      name: name,
      description: description,
      email: email,
      hashedPassword: hashed,
      userType: userType,
      avatarUrl: avatarUrl,
      theme: theme,
      language: (src['language'] ?? 'es').toString(),
      gameStreak: (src['gameStreak'] is int) ? src['gameStreak'] as int : 0,
      membership: membership,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
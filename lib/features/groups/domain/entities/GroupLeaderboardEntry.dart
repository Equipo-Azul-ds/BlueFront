class GroupLeaderboardEntry {
  final String userId;
  final String name;
  final int completedQuizzes;
  final int totalPoints;
  final int position;

  const GroupLeaderboardEntry({
    required this.userId,
    required this.name,
    required this.completedQuizzes,
    required this.totalPoints,
    required this.position,
  });

  factory GroupLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return GroupLeaderboardEntry(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Usuario',
      completedQuizzes: json['completedQuizzes'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
    );
  }
}

class GroupQuizCompletion {
  final String assignmentId;
  final String userId;
  final String quizAttemptId;
  final num score;
  final DateTime completedAt;

  const GroupQuizCompletion({
    required this.assignmentId,
    required this.userId,
    required this.quizAttemptId,
    required this.score,
    required this.completedAt,
  }) : assert(score >= 0);

  factory GroupQuizCompletion.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completedAt'] ?? json['completed_at'];
    return GroupQuizCompletion(
      assignmentId: json['assignmentId'] as String? ?? json['assignment_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      quizAttemptId: json['quizAttemptId'] as String? ?? json['quiz_attempt_id'] as String? ?? '',
      score: json['score'] as num? ?? 0,
      completedAt: completedRaw is String
          ? DateTime.parse(completedRaw)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'userId': userId,
      'quizAttemptId': quizAttemptId,
      'score': score,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

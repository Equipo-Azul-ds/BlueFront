class GroupQuizAssignment {
  final String id;
  final String groupId;
  final String quizId;
  final String quizTitle;
  final String assignedBy;
  final DateTime createdAt;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final bool isActive;
  final String status; 
  final int? attemptScore;

  const GroupQuizAssignment({
    required this.id,
    required this.groupId,
    required this.quizId,
    this.quizTitle = '',
    required this.assignedBy,
    required this.createdAt,
    required this.availableFrom,
    required this.availableUntil,
    required this.isActive,
    this.status = 'PENDING',
    this.attemptScore,
  });

  bool get isCompleted => status == 'COMPLETED';

  bool isAvailableAt(DateTime now) {
    if (!isActive) return false;
    if (now.isBefore(availableFrom)) return false;
    if (now.isAfter(availableUntil)) return false;
    return true;
  }

  factory GroupQuizAssignment.fromJson(Map<String, dynamic> json) {
    final availableFromRaw = json['availableFrom'] ?? json['available_from'];
    final availableUntilRaw = json['availableUntil'] ?? json['available_until'] ?? json['availableTo'];
    final createdRaw = json['createdAt'] ?? json['created_at'];
    final nestedQuiz = json['quiz'];
    String parsedTitle = '';
    if (json['quizTitle'] is String) {
      parsedTitle = json['quizTitle'] as String;
    } else if (json['title'] is String) {
      parsedTitle = json['title'] as String;
    } else if (nestedQuiz is Map<String, dynamic> && nestedQuiz['title'] is String) {
      parsedTitle = nestedQuiz['title'] as String;
    }

    // Extraer score de userResult o directo
    int? parsedScore;
    if (json['userResult'] != null && json['userResult']['score'] != null) {
      parsedScore = json['userResult']['score'] is int 
          ? json['userResult']['score'] 
          : int.tryParse(json['userResult']['score'].toString());
    } else if (json['score'] != null) {
      parsedScore = json['score'] is int 
          ? json['score'] 
          : int.tryParse(json['score'].toString());
    }

    return GroupQuizAssignment(
      id: json['id'] as String? ?? json['assignmentId'] as String? ?? '',
      groupId: json['groupId'] as String? ?? json['group_id'] as String? ?? '',
      quizId: json['quizId'] as String? ?? json['quiz_id'] as String? ?? '',
      quizTitle: parsedTitle,
      assignedBy: json['assignedBy'] as String? ?? json['assigned_by'] as String? ?? '',
      createdAt: createdRaw is String
          ? DateTime.parse(createdRaw)
          : DateTime.now(),
      availableFrom: availableFromRaw is String
          ? DateTime.parse(availableFromRaw)
          : DateTime.now(),
      availableUntil: availableUntilRaw is String
          ? DateTime.parse(availableUntilRaw)
          : DateTime.now(),
      isActive: (json['isActive'] ?? json['active'] ?? true) as bool,
      status: json['status'] as String? ?? 'PENDING',
      attemptScore: parsedScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'assignedBy': assignedBy,
      'createdAt': createdAt.toIso8601String(),
      'availableFrom': availableFrom.toIso8601String(),
      'availableUntil': availableUntil.toIso8601String(),
      'isActive': isActive,
      'status': status,
      'score': attemptScore,
    };
  }
}

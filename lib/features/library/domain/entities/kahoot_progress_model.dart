class KahootProgress {
  final String kahootId;
  final String userId;
  final bool isFavorite;
  final int progressPercentage;
  final DateTime lastAttemptAt;
  final bool isCompleted;

  const KahootProgress({
    required this.kahootId,
    required this.userId,
    this.isFavorite = false, // H7.2 (Favoritos)
    this.progressPercentage = 0, // H7.3 (En progreso)
    required this.lastAttemptAt,
    this.isCompleted = false, // H7.4 (Completado)
  });

  // Constructor de Serialización JSON
  factory KahootProgress.fromJson(Map<String, dynamic> json) {
    return KahootProgress(
      kahootId: json['kahootId'] as String,
      userId: json['userId'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      lastAttemptAt: DateTime.parse(json['lastAttemptAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  // Implementación de la igualdad
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KahootProgress &&
        other.kahootId == kahootId &&
        other.userId == userId;
  }

  // Implementación del HashCode
  @override
  int get hashCode => kahootId.hashCode ^ userId.hashCode;
}

class AdminNotificationEntity {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? senderName;
  final String? senderImage;

  AdminNotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.senderName,
    this.senderImage,
  });

  factory AdminNotificationEntity.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;

    return AdminNotificationEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sin título',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      senderName: sender?['name']?.toString(),
      senderImage: sender?['ImageUrl']?.toString(),
    );
  }
}
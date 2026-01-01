class Subscription {
  final String id;
  final String userId;
  final String planId;
  final DateTime? expiresAt;
  final String status;

  Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.expiresAt,
    required this.status,
  });
}

import '../../domain/entities/subscription.dart';

class SubscriptionModel extends Subscription {
  SubscriptionModel({
    required super.id,
    required super.userId,
    required super.planId,
    required super.expiresAt,
    required super.status,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final rawPlan = (json['plan'] ?? json['planId'] ?? 'FREE')
        .toString()
        .toUpperCase();
    final rawStatus = (json['status'] ?? 'inactive').toString().toLowerCase();

    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      planId: rawPlan,
      status: rawStatus,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': planId,
      'status': status,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

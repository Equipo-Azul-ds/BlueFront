import '../../domain/entities/subscription.dart';

class SubscriptionModel extends Subscription {
  SubscriptionModel({
    required super.id,
    required super.userId,
    required super.planId,
    required super.expiresAt,
    required super.status,
  });

  // Factory para convertir el JSON de la API en nuestro Modelo/Entidad
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      userId: json['userId'],
      planId: json['planId'],
      status: json['status'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  // Para enviar datos al servidor (POST /subscription)
  Map<String, dynamic> toJson() {
    return {'planId': planId};
  }
}

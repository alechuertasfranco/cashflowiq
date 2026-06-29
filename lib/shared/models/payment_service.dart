// lib/shared/models/payment_service.dart

class PaymentService {
  final int id;
  final int userId;
  final String name;
  final String serviceType;
  final int? accountId;
  final int? creditCardId;

  const PaymentService({
    required this.id,
    required this.userId,
    required this.name,
    required this.serviceType,
    this.accountId,
    this.creditCardId,
  });

  factory PaymentService.fromJson(Map<String, dynamic> json) => PaymentService(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        name: json['name'] as String,
        serviceType: json['service_type'] as String? ?? 'generic',
        accountId: json['account_id'] as int?,
        creditCardId: json['credit_card_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'service_type': serviceType,
        'account_id': accountId,
        'credit_card_id': creditCardId,
      };
}

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'payment_method_model.g.dart';

@HiveType(typeId: 5) // Changed to 5 to avoid conflict with SubscriptionList (4)
class PaymentMethod extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; 

  @HiveField(2)
  final String type; // 'Credit Card', 'Debit Card', 'PayPal', 'Digital Wallet', 'Other'

  @HiveField(3)
  final String? last4Digits;

  @HiveField(4)
  final int? colorValue; // For card color

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.last4Digits,
    this.colorValue,
  });

  factory PaymentMethod.create({
    required String name,
    required String type,
    String? last4Digits,
    int? colorValue,
  }) {
    return PaymentMethod(
      id: const Uuid().v4(),
      name: name,
      type: type,
      last4Digits: last4Digits,
      colorValue: colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'last4Digits': last4Digits,
        'colorValue': colorValue,
      };

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        last4Digits: j['last4Digits'] as String?,
        colorValue: j['colorValue'] as int?,
      );
}

import 'package:hive/hive.dart';

part 'price_record.g.dart';

/// Stores a historical price point for a subscription.
/// Appended whenever the subscription's amount is edited.
@HiveType(typeId: 6)
class PriceRecord extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime effectiveFrom;

  PriceRecord({
    required this.amount,
    required this.effectiveFrom,
  });
}

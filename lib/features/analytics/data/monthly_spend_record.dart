import 'package:hive/hive.dart';

part 'monthly_spend_record.g.dart';

/// Stores the total monthly spend for a given calendar month.
/// Key format: "YYYY-MM" (e.g. "2026-02").
/// Written whenever subscriptions are added, edited, or deleted.
@HiveType(typeId: 7)
class MonthlySpendRecord extends HiveObject {
  @HiveField(0)
  String monthKey; // "YYYY-MM"

  @HiveField(1)
  double totalSpend;

  @HiveField(2)
  DateTime recordedAt;

  MonthlySpendRecord({
    required this.monthKey,
    required this.totalSpend,
    required this.recordedAt,
  });
}

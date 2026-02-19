import 'package:hive/hive.dart';
import '../../subscriptions/data/subscription_model.dart';
import '../../analytics/analytics_engine.dart';
import 'monthly_spend_record.dart';

/// Writes a monthly spend snapshot to Hive whenever subscriptions change.
/// Call [record] after every add/update/delete in SubscriptionRepository.
class SpendHistoryService {
  static const String boxName = 'spend_history_v1';

  static Box<MonthlySpendRecord> get _box =>
      Hive.box<MonthlySpendRecord>(boxName);

  /// Computes current total monthly spend and upserts the record for this month.
  static Future<void> record(List<Subscription> allActiveSubs) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final total = allActiveSubs.fold(
      0.0,
      (sum, s) => sum + AnalyticsEngine.monthlyOf(s),
    );

    final existing = _box.get(key);
    if (existing != null) {
      existing.totalSpend = total;
      existing.recordedAt = now;
      await existing.save();
    } else {
      await _box.put(
        key,
        MonthlySpendRecord(monthKey: key, totalSpend: total, recordedAt: now),
      );
    }
  }

  /// Returns the monthly spend for a given month key ("YYYY-MM"), or null.
  static double? spendFor(String monthKey) => _box.get(monthKey)?.totalSpend;

  /// Returns all stored records sorted oldest→newest.
  static List<MonthlySpendRecord> allRecords() {
    final records = _box.values.toList();
    records.sort((a, b) => a.monthKey.compareTo(b.monthKey));
    return records;
  }
}

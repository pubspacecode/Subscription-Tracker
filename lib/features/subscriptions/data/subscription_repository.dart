import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/database/hive_service.dart';
import '../data/subscription_model.dart';
import '../data/price_record.dart';
import '../../analytics/data/spend_history_service.dart';
import '../../../core/notifications/notification_service.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(HiveService.subscriptionBox);
});

class SubscriptionRepository {
  final Box<Subscription> _box;

  SubscriptionRepository(this._box);

  List<Subscription> getAllSubscriptions() {
    return _box.values.where((s) => !s.isDeleted).toList();
  }

  List<Subscription> getAllHistory() {
    return _box.values.toList();
  }

  Future<void> addSubscription(Subscription subscription) async {
    await _box.put(subscription.id, subscription);
    await NotificationService().rescheduleSub(subscription);
    await _afterWrite();
  }

  /// Updates a subscription. If the amount changed, appends the old price
  /// to priceHistory before saving.
  Future<void> updateSubscription(Subscription subscription) async {
    final existing = _box.get(subscription.id);
    if (existing != null && existing.amount != subscription.amount) {
      // Record the old price before overwriting
      final history = List<PriceRecord>.from(subscription.priceHistory ?? []);
      history.add(PriceRecord(
        amount: existing.amount,
        effectiveFrom: existing.createdAt,
      ));
      subscription.priceHistory = history;
    }
    await subscription.save();
    await NotificationService().rescheduleSub(subscription);
    await _afterWrite();
  }

  Future<void> deleteSubscription(String id) async {
    final subscription = _box.get(id);
    if (subscription != null) {
      subscription.isDeleted = true;
      await subscription.save();
      await NotificationService().cancelNotification(NotificationService().getIdFromUuid(id));
      await NotificationService().cancelNotification((id.hashCode & 0x0FFFFFFF) | 0x10000000); // usage id
    }
    await _afterWrite();
  }

  Stream<List<Subscription>> watchSubscriptions() async* {
    yield _box.values.where((s) => !s.isDeleted).toList();
    yield* _box.watch().map((_) => _box.values.where((s) => !s.isDeleted).toList());
  }

  /// Called after every write: records spend snapshot.
  Future<void> _afterWrite() async {
    final activeSubs = _box.values.where((s) => !s.isDeleted && s.isActive).toList();
    await SpendHistoryService.record(activeSubs);
  }
}

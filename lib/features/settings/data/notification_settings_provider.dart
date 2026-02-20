import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../subscriptions/data/subscription_repository.dart';

class NotificationSettings {
  final bool areRenewalNotificationsEnabled;
  final TimeOfDay renewalNotificationTime;
  final bool areUsageNotificationsEnabled;
  final TimeOfDay usageNotificationTime;

  const NotificationSettings({
    required this.areRenewalNotificationsEnabled,
    required this.renewalNotificationTime,
    required this.areUsageNotificationsEnabled,
    required this.usageNotificationTime,
  });

  NotificationSettings copyWith({
    bool? areRenewalNotificationsEnabled,
    TimeOfDay? renewalNotificationTime,
    bool? areUsageNotificationsEnabled,
    TimeOfDay? usageNotificationTime,
  }) {
    return NotificationSettings(
      areRenewalNotificationsEnabled: areRenewalNotificationsEnabled ?? this.areRenewalNotificationsEnabled,
      renewalNotificationTime: renewalNotificationTime ?? this.renewalNotificationTime,
      areUsageNotificationsEnabled: areUsageNotificationsEnabled ?? this.areUsageNotificationsEnabled,
      usageNotificationTime: usageNotificationTime ?? this.usageNotificationTime,
    );
  }
}

final notificationSettingsProvider = NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(NotificationSettingsNotifier.new);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _renewalEnabledKey = 'notifications_enabled';
  static const _renewalHourKey = 'notification_time_hour';
  static const _renewalMinuteKey = 'notification_time_minute';
  static const _usageEnabledKey = 'usage_notifications_enabled';
  static const _usageHourKey = 'usage_notification_time_hour';
  static const _usageMinuteKey = 'usage_notification_time_minute';

  @override
  NotificationSettings build() {
    final box = HiveService.settingsBox;
    
    final renewalEnabled = box.get(_renewalEnabledKey, defaultValue: true);
    final renewalHour = box.get(_renewalHourKey, defaultValue: 9);
    final renewalMinute = box.get(_renewalMinuteKey, defaultValue: 0);
    
    final usageEnabled = box.get(_usageEnabledKey, defaultValue: false);
    final usageHour = box.get(_usageHourKey, defaultValue: 10);
    final usageMinute = box.get(_usageMinuteKey, defaultValue: 0);

    return NotificationSettings(
      areRenewalNotificationsEnabled: renewalEnabled,
      renewalNotificationTime: TimeOfDay(hour: renewalHour, minute: renewalMinute),
      areUsageNotificationsEnabled: usageEnabled,
      usageNotificationTime: TimeOfDay(hour: usageHour, minute: usageMinute),
    );
  }

  Future<void> toggleRenewalNotifications(bool value) async {
    state = state.copyWith(areRenewalNotificationsEnabled: value);
    final box = HiveService.settingsBox;
    await box.put(_renewalEnabledKey, value);
    await _rescheduleAll();
  }

  Future<void> updateRenewalTime(TimeOfDay newTime) async {
    state = state.copyWith(renewalNotificationTime: newTime);
    final box = HiveService.settingsBox;
    await box.put(_renewalHourKey, newTime.hour);
    await box.put(_renewalMinuteKey, newTime.minute);
    await _rescheduleAll();
  }

  Future<void> toggleUsageNotifications(bool value) async {
    state = state.copyWith(areUsageNotificationsEnabled: value);
    final box = HiveService.settingsBox;
    await box.put(_usageEnabledKey, value);
    await _rescheduleAll();
  }

  Future<void> updateUsageTime(TimeOfDay newTime) async {
    state = state.copyWith(usageNotificationTime: newTime);
    final box = HiveService.settingsBox;
    await box.put(_usageHourKey, newTime.hour);
    await box.put(_usageMinuteKey, newTime.minute);
    await _rescheduleAll();
  }

  Future<void> _rescheduleAll() async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final subs = repository.getAllSubscriptions();
    await NotificationService().rescheduleAll(subs);
  }
}

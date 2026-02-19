import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_service.dart';

class NotificationSettings {
  final bool areNotificationsEnabled;
  final TimeOfDay notificationTime;

  const NotificationSettings({
    required this.areNotificationsEnabled,
    required this.notificationTime,
  });

  NotificationSettings copyWith({
    bool? areNotificationsEnabled,
    TimeOfDay? notificationTime,
  }) {
    return NotificationSettings(
      areNotificationsEnabled: areNotificationsEnabled ?? this.areNotificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}

final notificationSettingsProvider = NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(NotificationSettingsNotifier.new);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _enabledKey = 'notifications_enabled';
  static const _hourKey = 'notification_time_hour';
  static const _minuteKey = 'notification_time_minute';

  @override
  NotificationSettings build() {
    final box = HiveService.settingsBox;
    final enabled = box.get(_enabledKey, defaultValue: true);
    final hour = box.get(_hourKey, defaultValue: 9);
    final minute = box.get(_minuteKey, defaultValue: 0);

    return NotificationSettings(
      areNotificationsEnabled: enabled,
      notificationTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(areNotificationsEnabled: value);
    final box = HiveService.settingsBox;
    await box.put(_enabledKey, value);
    // TODO: Cancel or Reschedule all notifications based on this toggle?
    // For now, we assume this flag checks before sending or when handling the event.
  }

  Future<void> updateTime(TimeOfDay newTime) async {
    state = state.copyWith(notificationTime: newTime);
    final box = HiveService.settingsBox;
    await box.put(_hourKey, newTime.hour);
    await box.put(_minuteKey, newTime.minute);
  }
}

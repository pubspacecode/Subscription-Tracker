import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_channels.dart';
import 'notification_styles.dart';
import '../database/hive_service.dart';
import '../../features/subscriptions/data/subscription_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Do NOT request permission at init — we ask contextually when the
    // user enables notifications in Settings (iOS best practice).
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Create the channel on Android
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation
        ?.createNotificationChannel(NotificationChannels.subscriptionChannel);
  }

  Future<bool> requestPermissions() async {
    // Android
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidImpl?.requestNotificationsPermission();

    // iOS / macOS
    final iOSImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final iOSGranted = await iOSImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? false) || (iOSGranted ?? false);
  }

  // ─── Core scheduling ────────────────────────────────────────────────────────

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.subscriptionRemindersId,
          NotificationChannels.subscriptionRemindersName,
          channelDescription: NotificationChannels.subscriptionRemindersDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─── Per-subscription scheduling ────────────────────────────────────────────
  
  /// Helper to get current global notification settings
  Map<String, dynamic> _getGlobalSettings() {
    final box = HiveService.settingsBox;
    return {
      'renewalEnabled': box.get('notifications_enabled', defaultValue: true),
      'renewalHour': box.get('notification_time_hour', defaultValue: 9),
      'renewalMinute': box.get('notification_time_minute', defaultValue: 0),
      'usageEnabled': box.get('usage_notifications_enabled', defaultValue: false),
      'usageHour': box.get('usage_notification_time_hour', defaultValue: 10),
      'usageMinute': box.get('usage_notification_time_minute', defaultValue: 0),
    };
  }

  /// Schedules a renewal reminder for [sub] if `reminderEnabled` is true.
  /// Uses global renewal time and sub's specific day offset.
  Future<void> scheduleRenewalNotification(Subscription sub) async {
    final global = _getGlobalSettings();
    if (!sub.reminderEnabled || !global['renewalEnabled']) {
      await cancelNotification(_renewalId(sub.id));
      return;
    }

    // Target date = renewal date minus the user's preferred offset (e.g., 0 for same day, 1 for 1 day before)
    final targetDate = sub.nextRenewalDate.subtract(Duration(days: sub.renewalReminderDays));
    
    // Set to global alert time
    final scheduledDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      global['renewalHour'],
      global['renewalMinute'],
    );

    // If it's already in the past, don't schedule
    if (scheduledDate.isBefore(DateTime.now())) return;

    final id = _renewalId(sub.id);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Upcoming Renewal: ${sub.name}',
      body: 'Your ${sub.name} subscription renews soon for ${sub.currency} ${sub.amount.toStringAsFixed(2)}.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.subscriptionRemindersId,
          NotificationChannels.subscriptionRemindersName,
          channelDescription: NotificationChannels.subscriptionRemindersDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedules a usage reminder for [sub] based on `usageNotificationFrequency`.
  /// Supports values like 'Every 1 day', 'Every 2 days', 'Every 1 week', etc.
  Future<void> scheduleUsageNotification(Subscription sub) async {
    final global = _getGlobalSettings();
    final freq = sub.usageNotificationFrequency;
    if (freq == null || freq.isEmpty || !global['usageEnabled']) {
      await cancelNotification(_usageId(sub.id));
      return;
    }

    final id = _usageId(sub.id);
    
    // Parse frequency: "Every X day(s)/week(s)"
    int days = 1;
    final parts = freq.split(' ');
    if (parts.length >= 3) {
      final value = int.tryParse(parts[1]) ?? 1;
      final unit = parts[2].toLowerCase();
      if (unit.contains('week')) {
        days = value * 7;
      } else {
        days = value;
      }
    }

    DateTime scheduledDate = DateTime.now().add(Duration(days: days));
    scheduledDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      global['usageHour'],
      global['usageMinute'],
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Using ${sub.name}?',
      body: 'You\'re paying for ${sub.name}. Make sure you\'re getting value from it!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.subscriptionRemindersId,
          NotificationChannels.subscriptionRemindersName,
          channelDescription: NotificationChannels.subscriptionRemindersDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: days == 1 ? DateTimeComponents.time : null,
    );
  }

  /// Cancels and reschedules notifications for one specific sub.
  Future<void> rescheduleSub(Subscription sub) async {
    await cancelNotification(_renewalId(sub.id));
    await cancelNotification(_usageId(sub.id));
    
    if (sub.isDeleted || !sub.isActive) return;

    await scheduleRenewalNotification(sub);
    await scheduleUsageNotification(sub);
  }

  /// Cancels and reschedules all notifications for the given active subscriptions.
  /// Call this after any subscription add/update/delete.
  Future<void> rescheduleAll(List<Subscription> activeSubs) async {
    // Cancel all existing scheduled notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    // Reschedule for each active sub
    for (final sub in activeSubs) {
      await scheduleRenewalNotification(sub);
      await scheduleUsageNotification(sub);
    }
  }

  // ─── Test & utilities ────────────────────────────────────────────────────────

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      NotificationChannels.subscriptionRemindersId,
      NotificationChannels.subscriptionRemindersName,
      channelDescription: NotificationChannels.subscriptionRemindersDescription,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'Your <b>Netflix</b> subscription is renewing tomorrow for <b>₹649.00</b>.<br>Review your subscription in the app.',
        htmlFormatBigText: true,
        contentTitle: '<b>Upcoming Renewal: Netflix</b>',
        htmlFormatContentTitle: true,
        summaryText: 'Renews in 1 day',
        htmlFormatSummaryText: true,
      ),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Upcoming Renewal: Netflix',
      body: 'Your Netflix subscription is renewing tomorrow.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  // ─── ID helpers ─────────────────────────────────────────────────────────────

  /// Unique int ID for renewal notifications (uses lower 28 bits of hashCode).
  int _renewalId(String uuid) => uuid.hashCode & 0x0FFFFFFF;

  /// Unique int ID for usage notifications (offset by 0x10000000 to avoid collision).
  int _usageId(String uuid) => (uuid.hashCode & 0x0FFFFFFF) | 0x10000000;

  // Keep for backward compat
  int getIdFromUuid(String uuid) => _renewalId(uuid);
}

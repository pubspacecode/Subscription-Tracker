import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_channels.dart';
import 'notification_styles.dart';
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

  /// Schedules a renewal reminder for [sub] if `reminderEnabled` is true.
  /// Fires 1 day before `nextRenewalDate`.
  Future<void> scheduleRenewalNotification(Subscription sub) async {
    if (!sub.reminderEnabled) return;

    final reminderDate = sub.nextRenewalDate.subtract(const Duration(days: 1));
    if (reminderDate.isBefore(DateTime.now())) return;

    final id = _renewalId(sub.id);
    await scheduleNotification(
      id: id,
      title: 'Upcoming Renewal: ${sub.name}',
      body:
          'Your ${sub.name} subscription renews tomorrow for ${sub.currency} ${sub.amount.toStringAsFixed(2)}.',
      scheduledDate: reminderDate,
    );
  }

  /// Schedules a usage reminder for [sub] based on `usageNotificationFrequency`.
  /// Values: 'Daily', 'Weekly', null/other = no usage notification.
  Future<void> scheduleUsageNotification(Subscription sub) async {
    final freq = sub.usageNotificationFrequency;
    if (freq == null || freq.isEmpty) return;

    final now = DateTime.now();
    DateTime nextFire;

    if (freq == 'Daily') {
      nextFire = DateTime(now.year, now.month, now.day + 1, 9, 0);
    } else if (freq == 'Weekly') {
      // Next Monday at 09:00
      final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      final days = daysUntilMonday == 0 ? 7 : daysUntilMonday;
      nextFire = DateTime(now.year, now.month, now.day + days, 9, 0);
    } else {
      return;
    }

    final id = _usageId(sub.id);
    await scheduleNotification(
      id: id,
      title: 'Using ${sub.name}?',
      body: 'You\'re paying for ${sub.name}. Make sure you\'re getting value from it!',
      scheduledDate: nextFire,
    );
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

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  static const String subscriptionRemindersId = 'subscription_reminders';
  static const String subscriptionRemindersName = 'Subscription Reminders';
  static const String subscriptionRemindersDescription = 'Notifications for subscription renewals';

  static const AndroidNotificationChannel subscriptionChannel = AndroidNotificationChannel(
    subscriptionRemindersId,
    subscriptionRemindersName,
    description: subscriptionRemindersDescription,
    importance: Importance.max,
    playSound: true,
  );
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationStyles {
  /// localized strings could be passed here in a real app
  static BigTextStyleInformation getRenewalStyle({
    required String subscriptionName,
    required String amount,
    required String renewalDate,
    required int daysRemaining,
  }) {
    return BigTextStyleInformation(
      'Your <b>$subscriptionName</b> subscription is renewing on <b>$renewalDate</b> for <b>$amount</b>.<br>Review your subscription in the app.',
      htmlFormatBigText: true,
      contentTitle: '<b>Upcoming Renewal: $subscriptionName</b>',
      htmlFormatContentTitle: true,
      summaryText: 'Renews in $daysRemaining days',
      htmlFormatSummaryText: true,
    );
  }

  static BigTextStyleInformation getTestStyle() {
    return const BigTextStyleInformation(
      'This is a test notification to verify your settings. <br><b>Everything looks good!</b>',
      htmlFormatBigText: true,
      contentTitle: '<b>Test Notification</b>',
      htmlFormatContentTitle: true,
      summaryText: 'System Check',
      htmlFormatSummaryText: true,
    );
  }
}

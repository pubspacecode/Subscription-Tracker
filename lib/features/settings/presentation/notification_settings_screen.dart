import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_settings_provider.dart';
import '../../../../core/notifications/notification_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Renewal Notifications Section ────────────────────────────
          _NotificationSection(
            children: [
              _SettingToggleRow(
                title: 'Renewal Notifications',
                subtitle: 'Get reminders before your subscriptions renew',
                value: settings.areRenewalNotificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    final granted = await NotificationService().requestPermissions();
                    if (!granted) {
                      if (context.mounted) {
                        _showPermissionDeniedDialog(context);
                      }
                      return;
                    }
                  }
                  notifier.toggleRenewalNotifications(value);
                },
              ),
              const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
              _SettingTimeRow(
                title: 'Renewal Notification Time',
                subtitle: 'Choose when you\'d like to receive renewal reminders.',
                time: settings.renewalNotificationTime,
                onTap: () async {
                  final newTime = await showTimePicker(
                    context: context,
                    initialTime: settings.renewalNotificationTime,
                  );
                  if (newTime != null) {
                    notifier.updateRenewalTime(newTime);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Usage Notifications Section ──────────────────────────────
          _NotificationSection(
            children: [
              _SettingToggleRow(
                title: 'Usage Notifications',
                subtitle: 'Get alerts based on your subscription usage patterns',
                value: settings.areUsageNotificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    final granted = await NotificationService().requestPermissions();
                    if (!granted) {
                      if (context.mounted) {
                        _showPermissionDeniedDialog(context);
                      }
                      return;
                    }
                  }
                  notifier.toggleUsageNotifications(value);
                },
              ),
              const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
              _SettingTimeRow(
                title: 'Usage Notification Time',
                subtitle: 'Choose when you\'d like to receive usage alerts.',
                time: settings.usageNotificationTime,
                onTap: () async {
                  final newTime = await showTimePicker(
                    context: context,
                    initialTime: settings.usageNotificationTime,
                  );
                  if (newTime != null) {
                    notifier.updateUsageTime(newTime);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Test Section ──────────────────────────────────────────────
          _NotificationSection(
            children: [
              ListTile(
                title: const Text('Send Test Notification', style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.notifications_active, color: Colors.purple, size: 20),
                onTap: () async {
                   await NotificationService().requestPermissions();
                   await NotificationService().showTestNotification();
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Test notification sent! Check your status bar.')),
                     );
                   }
                },
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  'Send a test to check they\'re working',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

        ],
      ),
    );
  }
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications Disabled',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Notification permission was denied.\n\nTo enable reminders, go to Settings → Subscription Tracker → Notifications and turn them on.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTimeRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _SettingTimeRow({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              time.format(context),
              style: const TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final List<Widget> children;

  const _NotificationSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

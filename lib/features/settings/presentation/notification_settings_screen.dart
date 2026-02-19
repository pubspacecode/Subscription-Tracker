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
          _NotificationSection(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enable Notifications', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Switch(
                      value: settings.areNotificationsEnabled,
                      onChanged: (value) async {
                        if (value) {
                          final granted = await NotificationService().requestPermissions();
                          if (!granted) {
                            // Permission denied — do not enable the toggle;
                            // guide user to open iOS Settings instead.
                            if (context.mounted) {
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
                            return; // don't enable toggle
                          }
                        }
                        notifier.toggleNotifications(value);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  'Get reminders before your subscriptions renew',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _NotificationSection(
            children: [
               ListTile(
                 title: const Text('Notification Time', style: TextStyle(color: Colors.white, fontSize: 16)),
                 trailing: Text(
                   settings.notificationTime.format(context),
                   style: const TextStyle(color: Colors.grey, fontSize: 16),
                 ),
                 onTap: () async {
                   final newTime = await showTimePicker(
                     context: context,
                     initialTime: settings.notificationTime,
                   );
                   if (newTime != null) {
                     notifier.updateTime(newTime);
                   }
                 },
               ),
               const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  'Choose when you\'d like to receive reminders.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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
}

class _NotificationSection extends StatelessWidget {
  final List<Widget> children;

  const _NotificationSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/presentation/widgets/bounceable.dart';
import '../../settings/data/currency_provider.dart';
import 'icloud_backup_screen.dart';
import '../data/notification_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // General Section
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('GENERAL', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: 'Preferred currency',
                trailing: Text('${selectedCurrency.code} ${selectedCurrency.symbol}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                showArrow: true,
                onTap: () => _showCurrencyDialog(context, ref, selectedCurrency),
              ),
              _SettingsTile(
                icon: Icons.list,
                title: 'Lists',
                showArrow: true,
                onTap: () => context.push('/settings/lists'),
              ),
              _SettingsTile(
                icon: Icons.sell, // Tag icon
                title: 'Categories',
                showArrow: true,
                onTap: () => context.push('/settings/categories'),
              ),
              _SettingsTile(
                icon: Icons.credit_card,
                title: 'Payment methods',
                showArrow: true,
                isLast: true,
                onTap: () => context.push('/settings/payment_methods'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notifications Section
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('NOTIFICATIONS', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                trailing: Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(notificationSettingsProvider);
                    final isOn = settings.areRenewalNotificationsEnabled || settings.areUsageNotificationsEnabled;
                    return Text(
                      isOn ? 'On' : 'Off',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    );
                  },
                ),
                showArrow: true,
                isLast: true,
                onTap: () => context.push('/settings/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Support Section
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('SUPPORT', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.mail_outline,
                title: 'Write to Support',
                isLast: false,
                onTap: () async {
                   final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'airsharetech@gmail.com',
                    query: 'subject=Subscription Tracker Support',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.ios_share,
                title: 'Share with a friend',
                isLast: true,
                onTap: () {
                   Share.share('Check out Subscription Tracker! It helps me manage all my recurring expenses.');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Section
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 8),
            child: Text('DATA', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.folder,
                title: 'Data',
                showArrow: true,
                isLast: !Platform.isIOS,
                onTap: () => context.push('/settings/data'),
              ),
              if (Platform.isIOS)
                _SettingsTile(
                  icon: Icons.cloud_done_rounded,
                  title: 'iCloud Backup',
                  showArrow: true,
                  isLast: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ICloudBackupScreen()),
                  ),
                ),
            ],
          ),

           const SizedBox(height: 40),
           // Bottom Navigation Bar Placeholder is handled by the main shell
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, Currency currentCurrency) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox( // Constrain height for long lists
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                   padding: EdgeInsets.symmetric(vertical: 20), 
                   child: Text('Select Currency', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: supportedCurrencies.length,
                    separatorBuilder: (ctx, index) => const Divider(height: 1, color: Color(0xFF2C2C2E)),
                    itemBuilder: (context, index) {
                      final currency = supportedCurrencies[index];
                      final isSelected = currency.code == currentCurrency.code;
                      return ListTile(
                        title: Text(
                          '${currency.code} ${currency.symbol}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        leading: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : const SizedBox(width: 20), // Placeholder for alignment
                        onTap: () {
                          ref.read(currencyProvider.notifier).setCurrency(currency);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showArrow;
  final bool isLast;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.showArrow = false,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: onTap,
      scaleFactor: 0.98,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 8),
                ],
                if (showArrow)
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              color: Color(0xFF2C2C2E),
              indent: 56, // Align with text start
            ),
        ],
      ),
    );
  }
}

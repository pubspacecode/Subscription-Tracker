import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../subscriptions/data/subscription_model.dart';
import '../../../../core/constants/theme.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';
import '../../../settings/data/currency_provider.dart';

class UpcomingRenewalsCard extends ConsumerWidget {
  final List<Subscription> subscriptions;

  const UpcomingRenewalsCard({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort by next renewal date
    final sortedSubs = List<Subscription>.from(subscriptions)
      ..sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));

    // Take top 3
    final upcoming = sortedSubs.take(3).toList();

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: upcoming.map((sub) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                SubscriptionIcon(
                  name: sub.name,
                  iconCodePoint: sub.iconCodePoint,
                  colorValue: sub.colorValue,
                  imagePath: sub.imagePath,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(sub.nextRenewalDate),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.simpleCurrency(name: ref.watch(currencyProvider).code).format(sub.amount),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

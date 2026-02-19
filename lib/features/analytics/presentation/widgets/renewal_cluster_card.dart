import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../settings/data/currency_provider.dart';
import '../../../subscriptions/data/subscription_model.dart';
import '../../analytics_engine.dart';
import '../analytics_detail_screen.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';

class RenewalClusterCard extends ConsumerWidget {
  final AnalyticsEngine engine;

  const RenewalClusterCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat.simpleCurrency(name: currency.code);
    final next30 = engine.renewalsInNextDays(30);
    final clusters = engine.renewalClusters;
    final now = DateTime.now();

    if (next30.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'No renewals in the next 30 days',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    // Build a set of days with renewals for the next 30 days
    final renewalDays = <int, List<Subscription>>{};
    for (final sub in next30) {
      final dayOffset = sub.nextRenewalDate
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      renewalDays.putIfAbsent(dayOffset, () => []).add(sub);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Next 30 Days',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${next30.length} renewals · ${fmt.format(engine.renewalsTotalInNextDays(30))}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar strip
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 30,
              itemBuilder: (context, dayOffset) {
                final date = DateTime(now.year, now.month, now.day)
                    .add(Duration(days: dayOffset));
                final hasSubs = renewalDays.containsKey(dayOffset);
                final subs = renewalDays[dayOffset] ?? [];
                final isToday = dayOffset == 0;
                final isHeavy = subs.length >= 3;

                return GestureDetector(
                  onTap: hasSubs
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnalyticsDetailScreen(
                                title:
                                    'Renewals on ${DateFormat('MMM d').format(date)}',
                                child: _RenewalDayDetail(
                                  subscriptions: subs,
                                  date: date,
                                  currency: currency.code,
                                ),
                              ),
                            ),
                          )
                      : null,
                  child: Container(
                    width: 44,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isHeavy
                          ? const Color(0xFFFF453A).withOpacity(0.15)
                          : hasSubs
                              ? Colors.purple.withOpacity(0.15)
                              : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? Colors.purple
                            : isHeavy
                                ? const Color(0xFFFF453A).withOpacity(0.5)
                                : Colors.transparent,
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: hasSubs ? Colors.white : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: hasSubs
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasSubs)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              subs.length.clamp(0, 3),
                              (i) => Container(
                                width: 4,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: isHeavy
                                      ? const Color(0xFFFF453A)
                                      : Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Cluster alerts
          if (clusters.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            ...clusters.map((cluster) => _ClusterAlert(
                  cluster: cluster,
                  fmt: fmt,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnalyticsDetailScreen(
                        title: 'Renewal Cluster',
                        child: _ClusterDetailContent(
                          cluster: cluster,
                          currency: currency.code,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _ClusterAlert extends StatelessWidget {
  final RenewalCluster cluster;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _ClusterAlert({
    required this.cluster,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = cluster.isHeavy
        ? const Color(0xFFFF453A)
        : const Color(0xFFFF9F0A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(
              cluster.isHeavy ? '⚡' : '📅',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cluster.isHeavy
                        ? 'Heavy renewal week'
                        : 'Renewal cluster',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${cluster.subscriptions.length} renewals · ${fmt.format(cluster.totalCost)} total',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _RenewalDayDetail extends StatelessWidget {
  final List<Subscription> subscriptions;
  final DateTime date;
  final String currency;

  const _RenewalDayDetail({
    required this.subscriptions,
    required this.date,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(name: currency);
    final total = subscriptions.fold<double>(0.0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Total: ${fmt.format(total)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...subscriptions.map<Widget>((sub) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SubscriptionIcon(
                    name: sub.name,
                    iconCodePoint: sub.iconCodePoint,
                    colorValue: sub.colorValue,
                    imagePath: sub.imagePath,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    fmt.format(sub.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList(),
      ],
    );
  }
}

class _ClusterDetailContent extends StatelessWidget {
  final RenewalCluster cluster;
  final String currency;

  const _ClusterDetailContent({
    required this.cluster,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency(name: currency);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFF453A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF453A).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                '${cluster.subscriptions.length} renewals within 7 days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Total expected: ${fmt.format(cluster.totalCost)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...cluster.subscriptions.map<Widget>((sub) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SubscriptionIcon(
                    name: sub.name,
                    iconCodePoint: sub.iconCodePoint,
                    colorValue: sub.colorValue,
                    imagePath: sub.imagePath,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d').format(sub.nextRenewalDate),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fmt.format(sub.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList(),
      ],
    );
  }
}

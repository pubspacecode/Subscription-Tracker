import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../settings/data/currency_provider.dart';
import '../../analytics_engine.dart';
import '../analytics_detail_screen.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';

class SubscriptionAgeCard extends ConsumerWidget {
  final AnalyticsEngine engine;

  const SubscriptionAgeCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat.simpleCurrency(name: currency.code);
    final ages = engine.subscriptionAges;

    if (ages.isEmpty) return const SizedBox.shrink();

    final oldest = ages.first;
    final maxMonths = oldest.monthsActive.clamp(1, 9999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🕰 Subscription Age',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalyticsDetailScreen(
                    title: 'Lifetime Spend',
                    child: _AgeDetailContent(ages: ages, fmt: fmt),
                  ),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'See all →',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal scroll of age cards
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final age = ages[index];
              final progress = maxMonths > 0
                  ? age.monthsActive / maxMonths
                  : 0.0;

              return Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: index == 0
                      ? Border.all(
                          color: Colors.amber.withOpacity(0.4),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubscriptionIcon(
                          name: age.subscription.name,
                          iconCodePoint: age.subscription.iconCodePoint,
                          colorValue: age.subscription.colorValue,
                          imagePath: age.subscription.imagePath,
                          size: 28,
                        ),
                        const Spacer(),
                        if (index == 0)
                          const Text('🏆',
                              style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      age.subscription.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      age.ageLabel,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == 0 ? Colors.amber : Colors.purple,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${fmt.format(age.lifetimeSpend)} lifetime',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AgeDetailContent extends StatelessWidget {
  final List<SubscriptionAge> ages;
  final NumberFormat fmt;

  const _AgeDetailContent({required this.ages, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final totalLifetime =
        ages.fold(0.0, (sum, a) => sum + a.lifetimeSpend);

    return Column(
      children: [
        // Total lifetime spend banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Total Lifetime Spend',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                fmt.format(totalLifetime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'across all ${ages.length} subscriptions',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Per-subscription breakdown
        ...ages.map((age) {
          final pct = totalLifetime > 0
              ? (age.lifetimeSpend / totalLifetime * 100)
              : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SubscriptionIcon(
                      name: age.subscription.name,
                      iconCodePoint: age.subscription.iconCodePoint,
                      colorValue: age.subscription.colorValue,
                      imagePath: age.subscription.imagePath,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            age.subscription.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            age.ageLabel,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt.format(age.lifetimeSpend),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.purple),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

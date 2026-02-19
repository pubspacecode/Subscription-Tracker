import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../settings/data/currency_provider.dart';
import '../../analytics_engine.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';

class WhatIfSimulatorCard extends ConsumerStatefulWidget {
  final AnalyticsEngine engine;

  const WhatIfSimulatorCard({super.key, required this.engine});

  @override
  ConsumerState<WhatIfSimulatorCard> createState() =>
      _WhatIfSimulatorCardState();
}

class _WhatIfSimulatorCardState extends ConsumerState<WhatIfSimulatorCard> {
  final Set<String> _removedIds = {};

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final fmt = NumberFormat.simpleCurrency(name: currency.code);
    final subs = widget.engine.subscriptions;
    final originalMonthly = widget.engine.monthlyTotal;
    final simulatedMonthly =
        widget.engine.simulateMonthlyWithout(_removedIds);
    final savings = originalMonthly - simulatedMonthly;
    final hasSavings = savings > 0.01;

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
                '🧮',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What if I cancel...?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Tap subscriptions to see your savings',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_removedIds.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _removedIds.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated totals
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasSavings
                  ? const Color(0xFF30D158).withOpacity(0.08)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasSavings
                    ? const Color(0xFF30D158).withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New monthly',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          fmt.format(simulatedMonthly),
                          key: ValueKey(simulatedMonthly),
                          style: TextStyle(
                            color: hasSavings
                                ? const Color(0xFF30D158)
                                : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSavings) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'You\'d save',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          '${fmt.format(savings)}/mo',
                          key: ValueKey(savings),
                          style: const TextStyle(
                            color: Color(0xFF30D158),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${fmt.format(savings * 12)}/yr',
                        style: TextStyle(
                          color: const Color(0xFF30D158).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Subscription toggles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subs.map((sub) {
              final isRemoved = _removedIds.contains(sub.id);
              final monthly = AnalyticsEngine.monthlyOf(sub);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isRemoved) {
                      _removedIds.remove(sub.id);
                    } else {
                      _removedIds.add(sub.id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isRemoved
                        ? const Color(0xFF30D158).withOpacity(0.1)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRemoved
                          ? const Color(0xFF30D158).withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRemoved)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF30D158),
                            size: 14,
                          ),
                        ),
                      SubscriptionIcon(
                        name: sub.name,
                        iconCodePoint: sub.iconCodePoint,
                        colorValue: sub.colorValue,
                        imagePath: sub.imagePath,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sub.name,
                        style: TextStyle(
                          color: isRemoved
                              ? const Color(0xFF30D158)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: isRemoved
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF30D158),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(monthly),
                        style: TextStyle(
                          color: isRemoved
                              ? const Color(0xFF30D158).withOpacity(0.7)
                              : Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

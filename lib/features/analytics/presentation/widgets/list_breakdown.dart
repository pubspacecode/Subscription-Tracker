import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../subscriptions/data/subscription_model.dart';
import '../../../../core/constants/theme.dart';
import '../../../settings/data/currency_provider.dart';

class ListBreakdown extends ConsumerStatefulWidget {
  final List<Subscription> subscriptions;

  const ListBreakdown({super.key, required this.subscriptions});

  @override
  ConsumerState<ListBreakdown> createState() => _ListBreakdownState();
}

class _ListBreakdownState extends ConsumerState<ListBreakdown> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.subscriptions.isEmpty) return const SizedBox.shrink();

    // Group by list and calculate monthly cost
    final listTotals = <String, double>{};
    double totalMonthly = 0;

    for (var sub in widget.subscriptions) {
      double monthlyCost = 0;
      
      double annualCost = 0;
      switch (sub.recurrencePeriod) {
        case 'Day':
          annualCost = sub.amount * 365 / sub.recurrenceFrequency;
          break;
        case 'Week':
          annualCost = sub.amount * 52 / sub.recurrenceFrequency;
          break;
        case 'Month':
          annualCost = sub.amount * 12 / sub.recurrenceFrequency;
          break;
        case 'Year':
          annualCost = sub.amount / sub.recurrenceFrequency;
          break;
        default:
          // Fallback to legacy
          switch (sub.billingCycle) {
            case BillingCycle.weekly:
              annualCost = sub.amount * 52;
              break;
            case BillingCycle.monthly:
              annualCost = sub.amount * 12;
              break;
            case BillingCycle.yearly:
              annualCost = sub.amount;
              break;
          }
      }
      monthlyCost = annualCost / 12;

      final listName = sub.listName ?? 'No List';
      listTotals[listName] = (listTotals[listName] ?? 0) + monthlyCost;
      totalMonthly += monthlyCost;
    }

    final sortedEntries = listTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors for the chart
    final List<Color> colors = [
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.lightGreen,
      Colors.deepOrange,
      Colors.blueGrey,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: List.generate(sortedEntries.length, (i) {
                  final entry = sortedEntries[i];
                  final isTouched = i == touchedIndex;
                  final fontSize = isTouched ? 16.0 : 0.0; // Hide text if not touched to avoid clutter
                  final radius = isTouched ? 60.0 : 50.0;
                  final percentage = (entry.value / totalMonthly * 100).toStringAsFixed(1);
                  final color = colors[i % colors.length];

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: '${percentage}%',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Column(
            children: List.generate(sortedEntries.length, (i) {
              final entry = sortedEntries[i];
              final color = colors[i % colors.length];
              final percentage = (entry.value / totalMonthly * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '$percentage%',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat.simpleCurrency(name: ref.watch(currencyProvider).code).format(entry.value),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../subscriptions/data/subscription_model.dart';
import '../../../settings/data/currency_provider.dart';

class SpendingChart extends ConsumerStatefulWidget {
  final List<Subscription> subscriptions;

  const SpendingChart({super.key, required this.subscriptions});

  @override
  ConsumerState<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends ConsumerState<SpendingChart> {
  int _projectionMonths = 6; // Default to 6 months

  @override
  Widget build(BuildContext context) {
    if (widget.subscriptions.isEmpty) return const SizedBox.shrink();
    
    final selectedCurrency = ref.watch(currencyProvider);

    // Calculate monthly spending for the selected months
    final now = DateTime.now();
    final monthlyData = <int, double>{};
    
    // Initialize months with 0
    for (int i = 0; i < _projectionMonths; i++) {
       monthlyData[i] = 0;
    }

    for (var sub in widget.subscriptions) {
      double amount = sub.amount;
      DateTime nextDate = sub.nextRenewalDate;
      
      final projectionEnd = DateTime(now.year, now.month + _projectionMonths, 0);

      // Project payments
      DateTime cursor = nextDate;
      
      // Optimization: avoid infinite loops if something is wrong
      int safeGuard = 0;
      
      while (cursor.isBefore(projectionEnd) && safeGuard < 1000) {
           safeGuard++;
           final monthDiff = (cursor.year - now.year) * 12 + cursor.month - now.month;
           
           if (monthDiff >= 0 && monthDiff < _projectionMonths) {
              monthlyData[monthDiff] = (monthlyData[monthDiff] ?? 0) + amount;
           }
           
           // Advance cursor
           // Advance cursor
           if (sub.recurrencePeriod == 'Day') {
             cursor = cursor.add(Duration(days: sub.recurrenceFrequency));
           } else if (sub.recurrencePeriod == 'Week') {
             cursor = cursor.add(Duration(days: 7 * sub.recurrenceFrequency));
           } else if (sub.recurrencePeriod == 'Month') {
             // Handle month overflow gracefully
             int newMonth = cursor.month + sub.recurrenceFrequency;
             int newYear = cursor.year + (newMonth - 1) ~/ 12;
             newMonth = (newMonth - 1) % 12 + 1;
             
             // Handle day clamping (e.g. Jan 31 + 1 month -> Feb 28)
             int newDay = cursor.day;
             final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
             if (newDay > daysInNewMonth) newDay = daysInNewMonth;
             
             cursor = DateTime(newYear, newMonth, newDay, cursor.hour, cursor.minute);
           } else if (sub.recurrencePeriod == 'Year') {
             cursor = DateTime(cursor.year + sub.recurrenceFrequency, cursor.month, cursor.day);
           } else {
             // Fallback
             switch (sub.billingCycle) {
               case BillingCycle.weekly:
                 cursor = cursor.add(const Duration(days: 7));
                 break;
               case BillingCycle.monthly:
                 cursor = DateTime(cursor.year, cursor.month + 1, cursor.day);
                 break;
               case BillingCycle.yearly:
                 cursor = DateTime(cursor.year + 1, cursor.month, cursor.day);
                 break;
             }
           }
      }
    }

    // Find max value for Y-axis
    double maxY = 0;
    monthlyData.forEach((_, value) {
      if (value > maxY) maxY = value;
    });
    // Add some buffer
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Container(
      height: 320, // Increased height for filter
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Projection',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              // Filter Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildFilterOption(6, '6M'),
                    _buildFilterOption(12, '1Y'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.purple,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        NumberFormat.simpleCurrency(name: selectedCurrency.code).format(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _projectionMonths) return const SizedBox.shrink();
                        
                        // Show fewer labels if 12 months
                        if (_projectionMonths == 12 && index % 2 != 0) return const SizedBox.shrink();

                        final date = DateTime(now.year, now.month + index, 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM').format(date),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_projectionMonths, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyData[index] ?? 0,
                        color: Colors.purple,
                        width: _projectionMonths == 12 ? 10 : 16, // Thinner bars for year view
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(int months, String label) {
    final isSelected = _projectionMonths == months;
    return GestureDetector(
      onTap: () => setState(() => _projectionMonths = months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

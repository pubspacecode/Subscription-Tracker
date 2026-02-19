import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../settings/data/currency_provider.dart';
import '../../settings/data/exchange_rate_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../data/subscription_model.dart';

class BillingHistoryScreen extends ConsumerWidget {
  final Subscription subscription;

  const BillingHistoryScreen({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(currencyProvider);
    final exchangeRatesAsync = ref.watch(exchangeRateProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final rates = exchangeRatesAsync.value ?? {};

    final convertedAmount = currencyService.convert(
        subscription.amount,
        subscription.currency,
        selectedCurrency.code,
        rates
    );

    final history = _generateBillingHistory();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Billing History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: history.isEmpty
          ? const Center(child: Text('No billing history yet.', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF2C2C2E), height: 32),
              itemBuilder: (context, index) {
                final date = history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('d MMM yyyy').format(date),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        NumberFormat.simpleCurrency(name: selectedCurrency.code).format(convertedAmount),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<DateTime> _generateBillingHistory() {
    final List<DateTime> dates = [];
    DateTime currentDate = subscription.nextRenewalDate;
    final now = DateTime.now();
    
    // We want past dates, so we start from nextRenewalDate and go backwards
    // However, nextRenewalDate is in the future. We need the *previous* cycles.

    // 1. Step back one cycle from nextRenewalDate to get the "current" or "last" payment
    currentDate = _previousDate(currentDate);

    // 2. Loop backwards until we reach createdAt
    while (currentDate.isAfter(subscription.createdAt) || isSameDay(currentDate, subscription.createdAt)) {
      if (currentDate.isBefore(now) || isSameDay(currentDate, now)) {
         dates.add(currentDate);
      }
      currentDate = _previousDate(currentDate);
      
      // Safety break to prevent infinite loops in case of weird dates
      if (dates.length > 500) break; 
    }
    
    // If the list is empty (e.g. new subscription created today), show today if it's the start
    if (dates.isEmpty && isSameDay(subscription.createdAt, now)) {
        // Actually if it's just created, and next renewal is in future, maybe no payment *yet*?
        // Usually you pay upfront. So createdAt is a payment.
        dates.add(subscription.createdAt);
    }
    
    // If we missed the 'createdAt' payment because of day-of-month alignment differences
    // (e.g. created on 31st, next renewal on 28th), ensure we at least have the start date if logic implies it.
    // For now, strict calculation based on cycle is safer.

    return dates;
  }

  DateTime _previousDate(DateTime date) {
    if (subscription.recurrencePeriod == 'Year') {
       return DateTime(date.year - subscription.recurrenceFrequency, date.month, date.day, date.hour, date.minute);
    } else if (subscription.recurrencePeriod == 'Month') {
       int newMonth = date.month - subscription.recurrenceFrequency;
       int newYear = date.year;
       while (newMonth <= 0) {
         newMonth += 12;
         newYear--;
       }
       int newDay = date.day;
       final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
       if (newDay > daysInNewMonth) newDay = daysInNewMonth;
       return DateTime(newYear, newMonth, newDay, date.hour, date.minute);
    } else if (subscription.recurrencePeriod == 'Week') {
       return date.subtract(Duration(days: 7 * subscription.recurrenceFrequency));
    } else if (subscription.recurrencePeriod == 'Day') {
       return date.subtract(Duration(days: 1 * subscription.recurrenceFrequency));
    } else {
      // Fallback
      if (subscription.billingCycle == BillingCycle.yearly) {
         return DateTime(date.year - 1, date.month, date.day, date.hour, date.minute);
      } else if (subscription.billingCycle == BillingCycle.weekly) {
         return date.subtract(const Duration(days: 7));
      } else {
         // Monthly fallback
         int newMonth = date.month - 1;
         int newYear = date.year;
         if (newMonth == 0) {
           newMonth = 12;
           newYear--;
         }
         int newDay = date.day;
         final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
         if (newDay > daysInNewMonth) newDay = daysInNewMonth;
         return DateTime(newYear, newMonth, newDay, date.hour, date.minute);
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

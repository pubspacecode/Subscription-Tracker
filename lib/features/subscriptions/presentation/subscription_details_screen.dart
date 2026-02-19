import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// import '../../../../core/constants/theme.dart'; // Unused
import '../../../../core/presentation/widgets/primary_button.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';
import '../../../../core/presentation/widgets/bounceable.dart';
import '../../settings/data/currency_provider.dart';
import '../../settings/data/exchange_rate_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../data/subscription_model.dart';
import '../data/subscription_repository.dart';

class SubscriptionDetailsScreen extends ConsumerWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(subscriptionRepositoryProvider);
    final selectedCurrency = ref.watch(currencyProvider);
    final exchangeRatesAsync = ref.watch(exchangeRateProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final rates = exchangeRatesAsync.value ?? {};

    double convertedAmount = currencyService.convert(
      subscription.amount, 
      subscription.currency, 
      selectedCurrency.code, 
      rates
    );

    // Calculate total spent (simple approximation: amount * months active)
    final duration = DateTime.now().difference(subscription.createdAt);
    final daysActive = duration.inDays;
    
    double totalSpent = 0;
    int daysPerCycle = 30;
    switch (subscription.recurrencePeriod) {
      case 'Day':
        daysPerCycle = 1 * subscription.recurrenceFrequency;
        break;
      case 'Week':
        daysPerCycle = 7 * subscription.recurrenceFrequency;
        break;
      case 'Month':
        daysPerCycle = 30 * subscription.recurrenceFrequency;
        break;
      case 'Year':
        daysPerCycle = 365 * subscription.recurrenceFrequency;
        break;
      default:
        // Fallback
        if (subscription.billingCycle == BillingCycle.weekly) daysPerCycle = 7;
        else if (subscription.billingCycle == BillingCycle.yearly) daysPerCycle = 365;
    }
    
    totalSpent = convertedAmount * (daysActive / daysPerCycle).ceil();
    if (totalSpent < convertedAmount) totalSpent = convertedAmount; // At least one payment

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Match app theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: PrimaryButton(
              onPressed: () {
                 context.push('/add_subscription?t=${DateTime.now().millisecondsSinceEpoch}', extra: {
                   'subscription': subscription,
                 });
              },
              text: 'Edit',
              height: 36,
              width: 80,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  SubscriptionIcon(
                    name: subscription.name,
                    iconCodePoint: subscription.iconCodePoint,
                    colorValue: subscription.colorValue,
                    imagePath: subscription.imagePath,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    subscription.name,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.simpleCurrency(name: selectedCurrency.code).format(convertedAmount),
                    style: TextStyle(color: Colors.grey[400], fontSize: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Billing Details
            _buildDetailRow('Billing', '${subscription.recurrenceFrequency > 1 ? 'Every ${subscription.recurrenceFrequency} ' : ''}${subscription.recurrencePeriod}s'),
            const Divider(color: Color(0xFF2C2C2E), height: 32),
            _buildDetailRow('Next payment', DateFormat('d MMM yyyy').format(subscription.nextRenewalDate)),
            const Divider(color: Color(0xFF2C2C2E), height: 32),
            _buildDetailRow('Total spent', NumberFormat.simpleCurrency(name: selectedCurrency.code).format(totalSpent)),
            const Divider(color: Color(0xFF2C2C2E), height: 32),
            _buildDetailRow('Subscribed', '$daysActive days'),
            const Divider(color: Color(0xFF2C2C2E), height: 32),
            _buildDetailRow('Category', subscription.category),

            const SizedBox(height: 48),

            // Billing History (Mock)
            Bounceable(
              onTap: () {
                context.push('/billing_history', extra: subscription);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Billing History', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Icon(Icons.history, color: Colors.grey[400], size: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildHistoryRow(DateFormat('d MMM yyyy').format(subscription.createdAt), 'Subscribed'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                onPressed: () async {
                  // Toggle active status
                  subscription.isActive = !subscription.isActive;
                  await repository.updateSubscription(subscription);
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(subscription.isActive ? 'Marked as Active' : 'Marked as Cancelled')),
                     );
                     context.pop(); 
                  }
                },
                text: subscription.isActive ? 'Mark as Cancelled' : 'Mark as Active',
                backgroundColor: subscription.isActive ? Colors.deepPurple : const Color(0xFF2C2C2E),
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1C1C1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: Text(
                        'Are you sure you want to delete "${subscription.name}"? This action cannot be undone.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                      ),
                      actions: [
                        // Cancel — ghost style
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Cancel'),
                        ),
                        // Confirm — red ghost style
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await repository.deleteSubscription(subscription.id);
                    if (context.mounted) context.pop();
                  }
                },
                text: 'Delete subscription',
                backgroundColor: Colors.transparent,
                borderColor: Colors.red,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildHistoryRow(String date, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(status, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/subscription_model.dart';
import '../data/subscription_repository.dart';
import '../application/statement_parser_service.dart';
import '../../../core/presentation/widgets/primary_button.dart';
import '../../../core/presentation/widgets/subscription_icon.dart';

class DetectedSubscriptionsScreen extends ConsumerStatefulWidget {
  final List<DetectedSubscription> subscriptions;

  const DetectedSubscriptionsScreen({super.key, required this.subscriptions});

  @override
  ConsumerState<DetectedSubscriptionsScreen> createState() => _DetectedSubscriptionsScreenState();
}

class _DetectedSubscriptionsScreenState extends ConsumerState<DetectedSubscriptionsScreen> {
  late List<DetectedSubscription> _availableSubscriptions;

  @override
  void initState() {
    super.initState();
    _availableSubscriptions = List.from(widget.subscriptions);
  }

  Future<void> _onSubscriptionTap(int index) async {
    final detected = _availableSubscriptions[index];
    
    // Map BillingCycle to recurrence
    String period = 'Month';
    if (detected.billingCycle == BillingCycle.yearly) period = 'Year';
    if (detected.billingCycle == BillingCycle.weekly) period = 'Week';

    final tempSubscription = Subscription.create(
      name: detected.name,
      amount: detected.amount,
      currency: 'USD',
      billingCycle: detected.billingCycle,
      nextRenewalDate: detected.nextDate,
      category: 'Other',
      reminderEnabled: true,
      recurrencePeriod: period,
      recurrenceFrequency: 1,
    );

    final result = await context.push('/add_subscription', extra: {'subscription': tempSubscription});

    if (result == true) {
      setState(() {
        _availableSubscriptions.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(
          'Detected ${_availableSubscriptions.length} possible services',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (_availableSubscriptions.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Text(
                '👇 Click on each item to review and add.',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          Expanded(
            child: _availableSubscriptions.isEmpty 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No more subscription services left to add',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _availableSubscriptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sub = _availableSubscriptions[index];
                    
                    return GestureDetector(
                      onTap: () => _onSubscriptionTap(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: SubscriptionIcon(
                                  name: sub.name,
                                  iconCodePoint: sub.iconCodePoint,
                                  colorValue: sub.colorValue,
                                  size: 40,
                                ),
                              ),
                              
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Last payment: ${DateFormat('MMM d, yyyy').format(sub.lastPaymentDate)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sub.frequencyCount} times paid',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Trailing
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${sub.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/bounceable.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';

import '../../../core/constants/theme.dart';
import '../../../core/database/hive_service.dart';
import '../data/subscription_model.dart';
import '../data/subscription_repository.dart';
import '../../settings/data/currency_provider.dart';
import 'filter_provider.dart';
import '../../settings/data/category_model.dart'; // Re-added for filtering logic if needed later
import '../../settings/data/subscription_list_model.dart'; // Re-added for filtering logic if needed later
import '../../settings/data/exchange_rate_provider.dart';
import '../../../../core/services/currency_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(subscriptionRepositoryProvider);
    final filterState = ref.watch(filterProvider);
    final selectedCurrency = ref.watch(currencyProvider);
    final exchangeRatesAsync = ref.watch(exchangeRateProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.push('/guide'),
          child: const Row(
            children: [
              Text('💁‍♂️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('Guide me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Bounceable(
              onTap: () {
                context.push('/paywall');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: repository.watchSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allSubscriptions = snapshot.data ?? [];
          
          // Apply Filters
          final subscriptions = allSubscriptions.where((sub) {
            if (!sub.isActive) return false;
            
            // Filter by List
            if (filterState.selectedListNames.isNotEmpty) {
              if (sub.listName == null || !filterState.selectedListNames.contains(sub.listName)) {
                return false;
              }
            }
            
            // Filter by Category
            if (filterState.selectedCategories.isNotEmpty) {
              if (!filterState.selectedCategories.contains(sub.category)) {
                return false;
              }
            }
            
            return true;
          }).toList();
          
          if (allSubscriptions.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No subscriptions yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/add'),
                    child: const Text('Add First Subscription'),
                  ),
                ],
              ),
            );
          }
          
          // Calculate Totals
          double monthlyTotal = 0;
          double yearlyTotal = 0;
          
          final rates = exchangeRatesAsync.value ?? {};

          for (var sub in subscriptions) {
            double amountInPreferred = currencyService.convert(
              sub.amount, 
              sub.currency, 
              selectedCurrency.code, 
              rates
            );

            double monthlyCost = 0;
            
            // Calculate annual cost first, then divide by 12
            double annualCost = 0;
            switch (sub.recurrencePeriod) {
              case 'Day':
                annualCost = amountInPreferred * 365 / sub.recurrenceFrequency;
                break;
              case 'Week':
                annualCost = amountInPreferred * 52 / sub.recurrenceFrequency;
                break;
              case 'Month':
                annualCost = amountInPreferred * 12 / sub.recurrenceFrequency;
                break;
              case 'Year':
                annualCost = amountInPreferred / sub.recurrenceFrequency;
                break;
              default:
                // Fallback to legacy
                switch (sub.billingCycle) {
                  case BillingCycle.weekly:
                    annualCost = amountInPreferred * 52;
                    break;
                  case BillingCycle.monthly:
                    annualCost = amountInPreferred * 12;
                    break;
                  case BillingCycle.yearly:
                    annualCost = amountInPreferred;
                    break;
                }
            }
            
            monthlyCost = annualCost / 12;
            monthlyTotal += monthlyCost;
            yearlyTotal += monthlyCost * 12;
          }

          // Sort by renewal date
          subscriptions.sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));

          // Cancelled subscriptions (inactive, not deleted)
          final cancelledSubscriptions = allSubscriptions
              .where((sub) => !sub.isActive)
              .toList();

          // Find upcoming bill
          final now = DateTime.now();
          final upcomingSubs = subscriptions.where((s) => s.isActive && (s.nextRenewalDate.isAfter(now) || isSameDay(s.nextRenewalDate, now))).toList();
          if (upcomingSubs.isNotEmpty) {
             upcomingSubs.sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));
          }
          final nextBill = upcomingSubs.isNotEmpty ? upcomingSubs.first : null;

          // Renewals in next 7 days
          final in7Days = DateTime.now().add(const Duration(days: 7));
          final renewalsThisWeek = subscriptions
              .where((s) => s.isActive && s.nextRenewalDate.isBefore(in7Days))
              .length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // ── Redesigned Dashboard Card ─────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A0533), Color(0xFF0D0221)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Orb decoration — top right
                              Positioned(
                                top: -40,
                                right: -40,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF6C63FF).withOpacity(0.35),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Orb decoration — bottom left
                              Positioned(
                                bottom: -30,
                                left: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF8E2DE2).withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Card content
                              Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: label + health badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Monthly Spend',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        if (nextBill != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.greenAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${subscriptions.length} Active',
                                                  style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Row 2: big monthly amount + /mo
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              NumberFormat.simpleCurrency(name: selectedCurrency.code).format(monthlyTotal),
                                              style: const TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                                          child: Text(
                                            '/mo',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Row 3: yearly
                                    Text(
                                      '${NumberFormat.simpleCurrency(name: selectedCurrency.code).format(yearlyTotal)} / year',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Divider
                                    Container(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                    const SizedBox(height: 16),
                                    // Row 4: 3 stat chips
                                    IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          // Upcoming bill chip
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Line 1: Name · Date
                                                RichText(
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: nextBill != null ? nextBill.name : 'No bills',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      if (nextBill != null)
                                                        TextSpan(
                                                          text: '  ·  ${_formatDate(nextBill.nextRenewalDate)}',
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.5),
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.normal,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Line 2: Amount · next bill
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      if (nextBill != null)
                                                        TextSpan(
                                                          text: NumberFormat.simpleCurrency(name: selectedCurrency.code).format(
                                                            currencyService.convert(nextBill.amount, nextBill.currency, selectedCurrency.code, rates),
                                                          ),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      TextSpan(
                                                        text: nextBill != null ? '  next bill' : '—',
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.4),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Vertical divider
                                          Container(
                                            width: 1,
                                            color: Colors.white.withOpacity(0.1),
                                            margin: const EdgeInsets.symmetric(horizontal: 14),
                                          ),
                                          // Renewals this week chip
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$renewalsThisWeek renewals',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'due this week',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.5),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Your Subscriptions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showFilterSheet(context, ref),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: filterState.hasFilters ? Colors.purple : const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list, 
                                    color: filterState.hasFilters ? Colors.white : Colors.grey, 
                                    size: 16
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filter', 
                                    style: TextStyle(
                                      color: filterState.hasFilters ? Colors.white : Colors.grey, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (subscriptions.isEmpty && allSubscriptions.isNotEmpty)
                 SliverToBoxAdapter(
                   child: Padding(
                     padding: const EdgeInsets.all(32.0),
                     child: Center(child: Text('No subscriptions match your filters', style: TextStyle(color: Colors.grey[600]))),
                   ),
                 ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sub = subscriptions[index];
                   // This is where the ListTile is rendered
                  return Bounceable(
                    onTap: () {
                      context.push('/subscription_details', extra: sub);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: SubscriptionIcon(
                          name: sub.name,
                          iconCodePoint: sub.iconCodePoint,
                          colorValue: sub.colorValue,
                          imagePath: sub.imagePath,
                          size: 34,
                        ),
                        title: Text(sub.name, style: AppTheme.subscriptionRowTitle),
                        subtitle: Text(
                          '${sub.recurrenceFrequency > 1 ? 'Every ${sub.recurrenceFrequency} ' : ''}${sub.recurrencePeriod}s • Next: ${DateFormat('MMM dd').format(sub.nextRenewalDate)}',
                          style: AppTheme.subscriptionRowSubtitle,
                        ),
                        trailing: Text(
                          NumberFormat.simpleCurrency(name: selectedCurrency.code).format(
                            currencyService.convert(sub.amount, sub.currency, selectedCurrency.code, rates)
                          ),
                          style: AppTheme.subscriptionRowAmount,
                        ),
                      ),
                    ),
                  );
                  },
                  childCount: subscriptions.length,
                ),
              ),
              // ── Cancelled Services Section ──────────────────────────────
              if (cancelledSubscriptions.isNotEmpty) ...
              [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
                    child: Text(
                      'CANCELLED SERVICES',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = cancelledSubscriptions[index];
                      return Opacity(
                        opacity: 0.5,
                        child: Bounceable(
                          onTap: () {
                            context.push('/subscription_details', extra: sub);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: SubscriptionIcon(
                                name: sub.name,
                                iconCodePoint: sub.iconCodePoint,
                                colorValue: sub.colorValue,
                                imagePath: sub.imagePath,
                                size: 34,
                              ),
                              title: Text(sub.name, style: AppTheme.subscriptionRowTitle),
                              subtitle: Text(
                                'Cancelled',
                                style: AppTheme.subscriptionRowSubtitle,
                              ),
                              trailing: Text(
                                NumberFormat.simpleCurrency(name: selectedCurrency.code).format(
                                  currencyService.convert(sub.amount, sub.currency, selectedCurrency.code, rates)
                                ),
                                style: AppTheme.subscriptionRowAmount,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: cancelledSubscriptions.length,
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Space for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }
}

class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var boxList = HiveService.listsBox;
    var boxCategory = HiveService.categoriesBox;
    
    // Safety check if boxes are not open, though they should be
    if (!boxList.isOpen || !boxCategory.isOpen) {
       return const SizedBox(height: 200, child: Center(child: Text('Loading...', style: TextStyle(color: Colors.white))));
    }

    final lists = boxList.values.toList();
    final categories = boxCategory.values.toList();
    final filterState = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Subscriptions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (filterState.hasFilters)
                  TextButton(
                    onPressed: () => notifier.clearAll(),
                    child: const Text('Reset', style: TextStyle(color: Colors.purple)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Lists Section
            const Text('Lists', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: lists.map((list) {
                final isSelected = filterState.selectedListNames.contains(list.name);
                return FilterChip(
                  label: Text(list.name),
                  selected: isSelected,
                  onSelected: (_) => notifier.toggleList(list.name),
                  backgroundColor: const Color(0xFF2C2C2E),
                  selectedColor: Colors.purple,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Categories Section
            const Text('Categories', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final isSelected = filterState.selectedCategories.contains(cat.name);
                return FilterChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (_) => notifier.toggleCategory(cat.name),
                  backgroundColor: const Color(0xFF2C2C2E),
                  selectedColor: Colors.purple,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
                        SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'Apply Filters',
                  backgroundColor: const Color(0xFF2C2C2E), 
                  borderColor: const Color(0xFF6C63FF),
                  width: double.infinity,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

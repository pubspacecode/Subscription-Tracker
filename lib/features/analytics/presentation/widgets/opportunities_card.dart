import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../subscriptions/data/subscription_model.dart';

class OpportunitiesCard extends StatefulWidget {
  final List<Subscription> subscriptions;

  const OpportunitiesCard({super.key, required this.subscriptions});

  @override
  State<OpportunitiesCard> createState() => _OpportunitiesCardState();
}

class _OpportunitiesCardState extends State<OpportunitiesCard> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OpportunityItem> _buildOpportunities() {
    final subs = widget.subscriptions;
    final items = <_OpportunityItem>[];

    // 1. Duplicates
    final nameMap = <String, List<Subscription>>{};
    for (var sub in subs) {
      final key = sub.name.toLowerCase().trim();
      nameMap.putIfAbsent(key, () => []).add(sub);
    }
    final duplicates =
        nameMap.values.where((l) => l.length > 1).expand((i) => i).toList();

    if (duplicates.isNotEmpty) {
      items.add(_OpportunityItem(
        icon: Icons.copy_rounded,
        color: Colors.orange,
        title: 'Duplicate Subscriptions',
        description:
            'You have multiple entries for "${duplicates.first.name}". Consider consolidating.',
        badge: 'Review duplicates',
      ));
    }

    // 2. Category overlap
    final categoryMap = <String, List<Subscription>>{};
    for (var sub in subs) {
      categoryMap.putIfAbsent(sub.category, () => []).add(sub);
    }
    final overlaps = categoryMap.entries
        .where((e) =>
            e.value.length > 1 &&
            e.key != 'Other' &&
            e.key != 'Utilities')
        .toList();

    for (var entry in overlaps) {
      if (duplicates.any((d) => d.category == entry.key)) continue;
      final names = entry.value.map((e) => e.name).join(', ');
      final total =
          entry.value.fold(0.0, (sum, s) => sum + _monthlyOf(s));
      items.add(_OpportunityItem(
        icon: Icons.category_rounded,
        color: Colors.blue,
        title: 'Multiple ${entry.key} Apps',
        description:
            '${entry.value.length} services in ${entry.key}: $names.',
        badge: '${NumberFormat.simpleCurrency().format(total)}/mo combined',
      ));
    }

    // 3. Switch to yearly
    final monthlySubs =
        subs.where((s) => s.billingCycle == BillingCycle.monthly).toList();
    for (var sub in monthlySubs) {
      if (sub.amount > 10) {
        final yearlyEst = sub.amount * 10;
        final currentYearly = sub.amount * 12;
        final saving = currentYearly - yearlyEst;
        items.add(_OpportunityItem(
          icon: Icons.calendar_today_rounded,
          color: Colors.green,
          title: 'Switch ${sub.name} to Yearly',
          description:
              'Paying monthly costs ${NumberFormat.simpleCurrency().format(currentYearly)}/yr.',
          badge:
              'Save ~${NumberFormat.simpleCurrency().format(saving)}/yr',
        ));
      }
    }

    // 4. High cost
    final highCost = subs.where((s) => _monthlyOf(s) > 50).toList();
    for (var sub in highCost) {
      if (duplicates.contains(sub)) continue;
      items.add(_OpportunityItem(
        icon: Icons.trending_up_rounded,
        color: Colors.red,
        title: 'High Cost: ${sub.name}',
        description:
            'Costs ${NumberFormat.simpleCurrency().format(sub.amount)} per ${sub.billingCycle.name}.',
        badge: 'Review necessity',
      ));
    }

    return items;
  }

  double _monthlyOf(Subscription sub) {
    switch (sub.billingCycle) {
      case BillingCycle.weekly:
        return sub.amount * 4.33;
      case BillingCycle.yearly:
        return sub.amount / 12;
      case BillingCycle.monthly:
        return sub.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = _buildOpportunities();

    if (opportunities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              'All clear!',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              'No optimisation opportunities found.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // PageView of cards
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: opportunities.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final item = opportunities[index];
              return Padding(
                // Small horizontal padding so adjacent card peeks
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _OpportunityCard(item: item),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Dot indicator + counter
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dots
            ...List.generate(opportunities.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.purple
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 10),
            Text(
              '${_currentPage + 1} / ${opportunities.length}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _OpportunityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String badge;

  const _OpportunityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.badge,
  });
}

class _OpportunityCard extends StatelessWidget {
  final _OpportunityItem item;

  const _OpportunityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  item.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.badge,
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

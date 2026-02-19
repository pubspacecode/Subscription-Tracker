import 'package:flutter/material.dart';
import '../subscriptions/data/subscription_model.dart';
import 'data/spend_history_service.dart';

/// A pure-Dart analytics computation class.
/// All calculations are local — no external calls.
class AnalyticsEngine {
  final List<Subscription> subscriptions;

  AnalyticsEngine(this.subscriptions);

  // ─── Monthly cost helper ────────────────────────────────────────────────────

  static double monthlyOf(Subscription sub) {
    double annual;
    switch (sub.recurrencePeriod) {
      case 'Day':
        annual = sub.amount * 365 / sub.recurrenceFrequency;
        break;
      case 'Week':
        annual = sub.amount * 52 / sub.recurrenceFrequency;
        break;
      case 'Month':
        annual = sub.amount * 12 / sub.recurrenceFrequency;
        break;
      case 'Year':
        annual = sub.amount / sub.recurrenceFrequency;
        break;
      default:
        switch (sub.billingCycle) {
          case BillingCycle.weekly:
            annual = sub.amount * 52;
            break;
          case BillingCycle.yearly:
            annual = sub.amount;
            break;
          case BillingCycle.monthly:
          default:
            annual = sub.amount * 12;
        }
    }
    return annual / 12;
  }

  // ─── Totals ─────────────────────────────────────────────────────────────────

  double get monthlyTotal =>
      subscriptions.fold(0.0, (sum, s) => sum + monthlyOf(s));

  double get annualTotal => monthlyTotal * 12;

  // ─── Renewals in next N days ─────────────────────────────────────────────────

  List<Subscription> renewalsInNextDays(int days) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return subscriptions
        .where((s) =>
            !s.nextRenewalDate.isBefore(DateTime(now.year, now.month, now.day)) &&
            s.nextRenewalDate.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));
  }

  double renewalsTotalInNextDays(int days) =>
      renewalsInNextDays(days).fold(0.0, (sum, s) => sum + s.amount);

  // ─── Month-over-month change ─────────────────────────────────────────────────
  // We approximate "last month" by looking at subscriptions whose next renewal
  // was in the previous calendar month (i.e. they already renewed).
  // Since we don't store history, we simulate last month's total by temporarily
  // rolling back nextRenewalDate by one period and recalculating.
  // Simpler approach: compare current monthly total vs a simulated "last month"
  // by checking which subs would have been active last month.

  /// Returns MoM % change.
  /// Uses real spend history from SpendHistoryService when available,
  /// falls back to approximation (exclude subs added this month) otherwise.
  double get momChangePercent {
    final now = DateTime.now();
    final thisKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final prevMonth = DateTime(now.year, now.month - 1);
    final prevKey =
        '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';

    final thisSpend = SpendHistoryService.spendFor(thisKey);
    final prevSpend = SpendHistoryService.spendFor(prevKey);

    if (thisSpend != null && prevSpend != null && prevSpend > 0) {
      return ((thisSpend - prevSpend) / prevSpend) * 100;
    }

    // Fallback: approximate using createdAt
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final previousSubs = subscriptions
        .where((s) => s.createdAt.isBefore(startOfThisMonth))
        .toList();
    if (previousSubs.isEmpty) return 0;
    final previousMonthly =
        previousSubs.fold(0.0, (sum, s) => sum + monthlyOf(s));
    if (previousMonthly == 0) return 0;
    return ((monthlyTotal - previousMonthly) / previousMonthly) * 100;
  }

  /// Trend classification based on MoM change.
  TrendLabel get trendLabel {
    final pct = momChangePercent;
    if (pct > 10) return TrendLabel.increasing;
    if (pct < -10) return TrendLabel.decreasing;
    return TrendLabel.stable;
  }

  // ─── Category totals ─────────────────────────────────────────────────────────

  Map<String, double> get categoryMonthlyTotals {
    final map = <String, double>{};
    for (final s in subscriptions) {
      map[s.category] = (map[s.category] ?? 0) + monthlyOf(s);
    }
    return map;
  }

  /// Returns the category that dominates spending (highest %).
  String? get dominantCategory {
    if (subscriptions.isEmpty) return null;
    final totals = categoryMonthlyTotals;
    return totals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double dominantCategoryPercent() {
    final totals = categoryMonthlyTotals;
    if (totals.isEmpty || monthlyTotal == 0) return 0;
    final maxVal = totals.values.reduce((a, b) => a > b ? a : b);
    return (maxVal / monthlyTotal) * 100;
  }

  // ─── Renewal clusters ─────────────────────────────────────────────────────────

  /// Groups renewals into 7-day windows. Returns clusters with 2+ renewals.
  List<RenewalCluster> get renewalClusters {
    final upcoming = renewalsInNextDays(30);
    if (upcoming.isEmpty) return [];

    final clusters = <RenewalCluster>[];
    final used = <String>{};

    for (int i = 0; i < upcoming.length; i++) {
      if (used.contains(upcoming[i].id)) continue;
      final anchor = upcoming[i].nextRenewalDate;
      final window = upcoming
          .where((s) =>
              !used.contains(s.id) &&
              s.nextRenewalDate
                  .difference(anchor)
                  .inDays
                  .abs() <= 7)
          .toList();
      if (window.length >= 2) {
        for (final s in window) {
          used.add(s.id);
        }
        clusters.add(RenewalCluster(
          subscriptions: window,
          windowStart: window.first.nextRenewalDate,
          windowEnd: window.last.nextRenewalDate,
          totalCost: window.fold(0.0, (sum, s) => sum + s.amount),
          isHeavy: window.length >= 3,
        ));
      }
    }
    return clusters;
  }

  // ─── Subscription age ─────────────────────────────────────────────────────────

  List<SubscriptionAge> get subscriptionAges {
    final now = DateTime.now();
    return subscriptions.map((s) {
      final start = s.startDate ?? s.createdAt;
      final months = (now.year - start.year) * 12 + now.month - start.month;

      // Weighted lifetime spend: use price history if available
      double lifetimeSpend;
      final history = s.priceHistory;
      if (history != null && history.isNotEmpty) {
        // Sort history oldest→newest
        final sorted = [...history]..sort(
            (a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
        lifetimeSpend = 0;
        for (int i = 0; i < sorted.length; i++) {
          final from = sorted[i].effectiveFrom;
          final to = i + 1 < sorted.length
              ? sorted[i + 1].effectiveFrom
              : now;
          final periodMonths =
              (to.year - from.year) * 12 + to.month - from.month;
          // Compute monthly rate for this price point
          final tempSub = s;
          final rate = monthlyOf(tempSub); // current rate as base
          // Use the historical amount directly as monthly proxy
          lifetimeSpend += sorted[i].amount * periodMonths.clamp(0, 9999);
        }
        // Add current price for remaining months
        final lastChange = sorted.last.effectiveFrom;
        final remainingMonths =
            (now.year - lastChange.year) * 12 + now.month - lastChange.month;
        lifetimeSpend += monthlyOf(s) * remainingMonths.clamp(0, 9999);
      } else {
        lifetimeSpend = monthlyOf(s) * months;
      }

      return SubscriptionAge(
        subscription: s,
        monthsActive: months.clamp(0, 9999),
        lifetimeSpend: lifetimeSpend,
      );
    }).toList()
      ..sort((a, b) => b.monthsActive.compareTo(a.monthsActive));
  }

  // ─── Health score ─────────────────────────────────────────────────────────────

  /// 0–100 score. Higher = healthier subscription portfolio.
  int get healthScore {
    int score = 100;

    // Penalise for duplicate categories (excluding "Other")
    final catMap = <String, int>{};
    for (final s in subscriptions) {
      catMap[s.category] = (catMap[s.category] ?? 0) + 1;
    }
    final overlaps = catMap.entries
        .where((e) => e.value > 1 && e.key != 'Other')
        .length;
    score -= overlaps * 8;

    // Penalise for heavy renewal cluster
    if (renewalClusters.any((c) => c.isHeavy)) score -= 10;

    // Penalise if one category dominates > 60%
    if (dominantCategoryPercent() > 60) score -= 10;

    // Penalise for rising trend
    if (trendLabel == TrendLabel.increasing) score -= 10;

    // Penalise for free trials (risk of forgetting)
    final freeTrials = subscriptions.where((s) => s.isFreeTrial).length;
    score -= freeTrials * 5;

    return score.clamp(0, 100);
  }

  String get healthLabel {
    final s = healthScore;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Fair';
    return 'Needs Review';
  }

  // ─── Smart signals ─────────────────────────────────────────────────────────

  List<SmartSignal> get smartSignals {
    final signals = <SmartSignal>[];
    final mom = momChangePercent;
    final trend = trendLabel;
    final next7 = renewalsInNextDays(7);
    final clusters = renewalClusters;
    final domPct = dominantCategoryPercent();
    final domCat = dominantCategory;

    if (mom.abs() > 5) {
      final up = mom > 0;
      signals.add(SmartSignal(
        icon: up ? '📈' : '📉',
        title: up
            ? 'Spending up ${mom.toStringAsFixed(0)}% this month'
            : 'Spending down ${mom.abs().toStringAsFixed(0)}% this month',
        subtitle: up
            ? 'New subscriptions added this month increased your total.'
            : 'You removed subscriptions — great work!',
        type: up ? SignalType.warning : SignalType.positive,
      ));
    }

    if (trend == TrendLabel.stable) {
      signals.add(const SmartSignal(
        icon: '✅',
        title: 'Stable spending pattern',
        subtitle: 'Your subscription costs have been consistent.',
        type: SignalType.positive,
      ));
    }

    if (next7.length >= 3) {
      signals.add(SmartSignal(
        icon: '📅',
        title: '${next7.length} renewals due this week',
        subtitle: 'Multiple charges coming up — plan ahead.',
        type: SignalType.warning,
      ));
    }

    if (clusters.any((c) => c.isHeavy)) {
      signals.add(const SmartSignal(
        icon: '⚡',
        title: 'Heavy renewal week detected',
        subtitle: '3 or more subscriptions renew within a 7-day window.',
        type: SignalType.alert,
      ));
    }

    if (domPct > 40 && domCat != null) {
      signals.add(SmartSignal(
        icon: '🎯',
        title: '$domCat takes ${domPct.toStringAsFixed(0)}% of spending',
        subtitle: 'One category dominates your subscription budget.',
        type: SignalType.info,
      ));
    }

    // Duplicate category alert
    final catMap = <String, int>{};
    for (final s in subscriptions) {
      catMap[s.category] = (catMap[s.category] ?? 0) + 1;
    }
    final overlappingCats = catMap.entries
        .where((e) => e.value > 1 && e.key != 'Other')
        .map((e) => e.key)
        .toList();
    if (overlappingCats.isNotEmpty) {
      signals.add(SmartSignal(
        icon: '🔁',
        title: 'Overlapping ${overlappingCats.first} subscriptions',
        subtitle:
            'You have ${catMap[overlappingCats.first]} services in the same category.',
        type: SignalType.warning,
      ));
    }

    // Free trial reminder
    final trials = subscriptions.where((s) => s.isFreeTrial).toList();
    if (trials.isNotEmpty) {
      signals.add(SmartSignal(
        icon: '⏳',
        title: '${trials.length} free trial${trials.length > 1 ? 's' : ''} active',
        subtitle: 'Don\'t forget to cancel before they convert.',
        type: SignalType.alert,
      ));
    }

    return signals;
  }

  // ─── What-if simulation ───────────────────────────────────────────────────

  /// Returns monthly total if the given subscription IDs are excluded.
  double simulateMonthlyWithout(Set<String> excludedIds) {
    return subscriptions
        .where((s) => !excludedIds.contains(s.id))
        .fold(0.0, (sum, s) => sum + monthlyOf(s));
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

enum TrendLabel { stable, increasing, decreasing }

class RenewalCluster {
  final List<Subscription> subscriptions;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double totalCost;
  final bool isHeavy;

  const RenewalCluster({
    required this.subscriptions,
    required this.windowStart,
    required this.windowEnd,
    required this.totalCost,
    required this.isHeavy,
  });
}

class SubscriptionAge {
  final Subscription subscription;
  final int monthsActive;
  final double lifetimeSpend;

  const SubscriptionAge({
    required this.subscription,
    required this.monthsActive,
    required this.lifetimeSpend,
  });

  String get ageLabel {
    if (monthsActive < 1) return 'New';
    final years = monthsActive ~/ 12;
    final months = monthsActive % 12;
    if (years == 0) return '${months}mo';
    if (months == 0) return '${years}yr';
    return '${years}yr ${months}mo';
  }
}

enum SignalType { positive, warning, alert, info }

class SmartSignal {
  final String icon;
  final String title;
  final String subtitle;
  final SignalType type;

  const SmartSignal({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  Color get color {
    switch (type) {
      case SignalType.positive:
        return const Color(0xFF30D158);
      case SignalType.warning:
        return const Color(0xFFFF9F0A);
      case SignalType.alert:
        return const Color(0xFFFF453A);
      case SignalType.info:
        return const Color(0xFF0A84FF);
    }
  }
}

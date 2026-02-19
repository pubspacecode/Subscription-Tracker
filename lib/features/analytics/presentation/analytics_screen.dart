import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../subscriptions/data/subscription_model.dart';
import '../analytics_engine.dart';
import 'widgets/smart_overview_card.dart';
import 'widgets/smart_signals_card.dart';
import 'widgets/renewal_cluster_card.dart';
import 'widgets/subscription_age_card.dart';
import 'widgets/what_if_simulator_card.dart';
import 'widgets/spending_chart.dart';
import 'widgets/breakdown_pager.dart';
import 'widgets/opportunities_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(subscriptionRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: repository.watchSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subscriptions = snapshot.data ?? [];
          final activeSubscriptions =
              subscriptions.where((s) => s.isActive).toList();

          if (activeSubscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📊', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'No active subscriptions to analyze',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add subscriptions to see insights',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final engine = AnalyticsEngine(activeSubscriptions);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Smart Overview Hero Card ──────────────────────────
                SmartOverviewCard(engine: engine),
                const SizedBox(height: 24),

                // ── 2. Smart Signals ─────────────────────────────────────
                if (engine.smartSignals.isNotEmpty) ...[
                  SmartSignalsCard(engine: engine),
                  const SizedBox(height: 24),
                ],

                // ── 3. Spending Trend Chart ───────────────────────────────
                _SectionHeader(
                  emoji: '↗',
                  title: 'Spending Trend',
                  subtitle: _trendSubtitle(engine),
                ),
                const SizedBox(height: 12),
                SpendingChart(subscriptions: activeSubscriptions),
                const SizedBox(height: 24),

                // ── 4. Renewal Calendar ───────────────────────────────────
                _SectionHeader(
                  emoji: '◈',
                  title: 'Renewal Calendar',
                  subtitle:
                      '${engine.renewalsInNextDays(30).length} upcoming in 30 days',
                ),
                const SizedBox(height: 12),
                RenewalClusterCard(engine: engine),
                const SizedBox(height: 24),

                // ── 5. Breakdown Pager (Category + List) ─────────────────
                const _SectionHeader(
                  emoji: '◉',
                  title: 'Spending Breakdown',
                  subtitle: 'Swipe to switch views',
                ),
                const SizedBox(height: 12),
                BreakdownPager(subscriptions: activeSubscriptions),
                const SizedBox(height: 24),

                // ── 7. Subscription Age ───────────────────────────────────
                SubscriptionAgeCard(engine: engine),
                const SizedBox(height: 24),

                // ── 8. What-If Simulator ──────────────────────────────────
                const _SectionHeader(
                  emoji: '',
                  title: 'Cancel Simulator',
                  subtitle: 'See your savings before you cancel',
                ),
                const SizedBox(height: 12),
                WhatIfSimulatorCard(engine: engine),
                const SizedBox(height: 24),

                // ── 9. Cost Saving Opportunities ──────────────────────────
                const _SectionHeader(
                  emoji: '◆',
                  title: 'Opportunities',
                  subtitle: 'Ways to optimise your spending',
                ),
                const SizedBox(height: 12),
                OpportunitiesCard(subscriptions: activeSubscriptions),
              ],
            ),
          );
        },
      ),
    );
  }

  String _trendSubtitle(AnalyticsEngine engine) {
    final mom = engine.momChangePercent;
    final trend = engine.trendLabel;
    if (mom.abs() < 1) return 'Stable spending pattern';
    final dir = mom > 0 ? '↑' : '↓';
    final label = trend == TrendLabel.increasing ? 'Rising' : 'Falling';
    return '$dir ${mom.abs().toStringAsFixed(1)}% · $label';
  }
}

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (emoji.isNotEmpty) ...[
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

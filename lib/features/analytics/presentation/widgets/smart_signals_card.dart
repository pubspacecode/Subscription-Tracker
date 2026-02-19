import 'package:flutter/material.dart';
import '../../analytics_engine.dart';
import '../analytics_detail_screen.dart';

class SmartSignalsCard extends StatelessWidget {
  final AnalyticsEngine engine;

  const SmartSignalsCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final signals = engine.smartSignals;
    if (signals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⚡ Smart Signals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${signals.length} insights',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: signals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final signal = signals[index];
              return _SignalChip(
                signal: signal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnalyticsDetailScreen(
                      title: 'Signal Detail',
                      child: _SignalDetailContent(signal: signal),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SignalChip extends StatelessWidget {
  final SmartSignal signal;
  final VoidCallback onTap;

  const _SignalChip({required this.signal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: signal.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: signal.color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(signal.icon, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: signal.color.withOpacity(0.5),
                  size: 12,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              signal.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalDetailContent extends StatelessWidget {
  final SmartSignal signal;

  const _SignalDetailContent({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: signal.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: signal.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(signal.icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            signal.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            signal.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: signal.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _actionLabel(signal.type),
              style: TextStyle(
                color: signal.color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(SignalType type) {
    switch (type) {
      case SignalType.positive:
        return '✓ Keep it up!';
      case SignalType.warning:
        return '⚠ Worth reviewing';
      case SignalType.alert:
        return '🔴 Action recommended';
      case SignalType.info:
        return 'ℹ For your awareness';
    }
  }
}

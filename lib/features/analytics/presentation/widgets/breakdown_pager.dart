import 'package:flutter/material.dart';
import '../../../subscriptions/data/subscription_model.dart';
import 'category_breakdown.dart';
import 'list_breakdown.dart';

/// Swipeable PageView containing Category Breakdown and List Breakdown.
class BreakdownPager extends StatefulWidget {
  final List<Subscription> subscriptions;

  const BreakdownPager({super.key, required this.subscriptions});

  @override
  State<BreakdownPager> createState() => _BreakdownPagerState();
}

class _BreakdownPagerState extends State<BreakdownPager> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> _titles = ['Category Breakdown', 'List Breakdown'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab row
        Row(
          children: List.generate(_titles.length, (i) {
            final isActive = i == _currentPage;
            return GestureDetector(
              onTap: () {
                _controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.purple
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _titles[i],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[400],
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // PageView
        SizedBox(
          height: 380,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              CategoryBreakdown(subscriptions: widget.subscriptions),
              ListBreakdown(subscriptions: widget.subscriptions),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_titles.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.purple
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

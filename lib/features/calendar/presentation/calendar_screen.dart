import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/bounceable.dart';
import '../../../../core/presentation/widgets/subscription_icon.dart';

import '../../../core/constants/theme.dart';

import '../../../core/constants/categories.dart';

import '../../settings/data/currency_provider.dart';
import '../../subscriptions/data/subscription_model.dart';
import '../../subscriptions/data/subscription_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Subscription> _getEventsForDay(DateTime day, List<Subscription> realSubscriptions) {
    return realSubscriptions.where((sub) {
      if (!sub.isActive) return false;
      return isSameDay(sub.nextRenewalDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(subscriptionRepositoryProvider);
    final selectedCurrency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C63FF), width: 1.5),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
            final realSubscriptions = snapshot.data ?? [];

            final events = _selectedDay != null ? _getEventsForDay(_selectedDay!, realSubscriptions) : <Subscription>[];
            double totalAmount = 0;
            if (events.isNotEmpty) {
               totalAmount = events.fold(0.0, (sum, item) => sum + item.amount);
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TableCalendar<Subscription>(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      eventLoader: (day) => _getEventsForDay(day, realSubscriptions),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekendStyle: TextStyle(color: Colors.grey),
                        weekdayStyle: TextStyle(color: Colors.grey),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.white),
                        outsideTextStyle: const TextStyle(color: Colors.grey),
                        markerDecoration: const BoxDecoration(
                          color: Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
                if (_selectedDay == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Select a date', style: TextStyle(color: Colors.grey))),
                  )
                else if (events.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No renewals on this day', style: TextStyle(color: Colors.grey))),
                  )
                else ...[
                   SliverToBoxAdapter(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             DateFormat('d MMMM y').format(_selectedDay!),
                             style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                           ),
                           Text(
                             '${NumberFormat.simpleCurrency(name: selectedCurrency.code).currencySymbol}${totalAmount.toStringAsFixed(2)} Total',
                             style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                           ),
                         ],
                       ),
                     ),
                   ),
                   SliverPadding(
                     padding: EdgeInsets.zero,
                     sliver: SliverList(
                       delegate: SliverChildBuilderDelegate(
                         (context, index) {
                           final sub = events[index];
                           final daysRemaining = sub.nextRenewalDate.difference(DateTime.now()).inDays;
                           
                           return Bounceable(
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
                                    'Renews in ${daysRemaining < 0 ? 0 : daysRemaining} days • ${DateFormat('MMM dd').format(sub.nextRenewalDate)}',
                                    style: AppTheme.subscriptionRowSubtitle,
                                  ),
                                  trailing: Text(
                                    NumberFormat.simpleCurrency(name: selectedCurrency.code).format(sub.amount),
                                    style: AppTheme.subscriptionRowAmount,
                                  ),
                                ),
                              ),
                            );
                         },
                         childCount: events.length,
                       ),
                     ),
                   ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            );
          }),
    );
  }
}

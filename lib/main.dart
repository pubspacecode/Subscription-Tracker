import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_tracker/features/settings/presentation/settings_screen.dart';
import 'package:subscription_tracker/features/settings/presentation/lists_screen.dart';
import 'package:subscription_tracker/features/settings/presentation/categories_screen.dart';
import 'package:subscription_tracker/features/settings/presentation/notification_settings_screen.dart';
import 'package:subscription_tracker/features/settings/presentation/data_settings_screen.dart';
import 'package:subscription_tracker/features/settings/presentation/payment_methods_screen.dart';
import 'package:subscription_tracker/features/subscriptions/presentation/add_subscription_screen.dart';

import 'app/main_wrapper.dart';
import 'core/constants/theme.dart';
import 'core/presentation/animations/smooth_transitions.dart';
import 'core/database/hive_service.dart';
import 'core/notifications/notification_service.dart';
import 'features/calendar/presentation/calendar_screen.dart';
import 'features/subscriptions/presentation/home_screen.dart';
import 'features/subscriptions/presentation/subscription_selection_screen.dart';
import 'features/analytics/presentation/analytics_screen.dart';

import 'features/subscriptions/presentation/subscription_details_screen.dart';
import 'features/subscriptions/data/subscription_model.dart';

import 'features/paywall/presentation/paywall_screen.dart';

import 'features/subscriptions/presentation/billing_history_screen.dart';
import 'features/subscriptions/presentation/detected_subscriptions_screen.dart';
import 'features/subscriptions/application/statement_parser_service.dart';
import 'features/subscriptions/presentation/guide_screen.dart';


import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await HiveService.init();
  await NotificationService().init();

  runApp(const ProviderScope(child: SubscriptionTrackerApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'lists',
                  builder: (context, state) => const ListsScreen(),
                ),
                GoRoute(
                  path: 'categories',
                  builder: (context, state) => const CategoriesScreen(),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) => const NotificationSettingsScreen(),
                ),
                GoRoute(
                  path: 'payment_methods',
                  builder: (context, state) => const PaymentMethodsScreen(),
                ),
                GoRoute(
                  path: 'data',
                  builder: (context, state) => const DataSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/subscription_details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final subscription = state.extra as Subscription;
        return SubscriptionDetailsScreen(subscription: subscription);
      },
    ),
    GoRoute(
      path: '/add',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.slideUpPage(
        key: state.pageKey,
        child: const SubscriptionSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/add_subscription',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        
        final initialName = extra?['name'] as String?;
        final initialIconCodePoint = extra?['iconCodePoint'] as int?;
        final initialColorValue = extra?['colorValue'] as int?;
        final initialImagePath = extra?['imagePath'] as String?;
        final initialAmount = extra?['amount'] as String?;
        final initialNextRenewalDate = extra?['nextRenewalDate'] as DateTime?;
        final subscription = extra?['subscription'] as Subscription?;
        final shouldParse = extra?['shouldParse'] as bool? ?? false;
        
        return AppTransitions.slideUpPage(
          key: state.pageKey,
          child: AddSubscriptionScreen(
            initialName: initialName,
            initialIconCodePoint: initialIconCodePoint,
            initialColorValue: initialColorValue,
            subscription: subscription,
            initialAmount: initialAmount,
            initialNextRenewalDate: initialNextRenewalDate,
            initialImagePath: initialImagePath,
            shouldParse: shouldParse,
          ),
        );
      },
    ),
    GoRoute(
      path: '/paywall',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.slideUpPage(
        key: state.pageKey,
        child: const PaywallScreen(),
      ),
    ),
    GoRoute(
      path: '/guide',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.slideUpPage(
        key: state.pageKey,
        child: const GuideScreen(),
      ),
    ),
    GoRoute(
      path: '/billing_history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final subscription = state.extra as Subscription;
        return BillingHistoryScreen(subscription: subscription);
      },
    ),

    GoRoute(
      path: '/detected_subscriptions',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final subscriptions = state.extra as List<DetectedSubscription>;
        return AppTransitions.slideUpPage(
          key: state.pageKey,
          child: DetectedSubscriptionsScreen(subscriptions: subscriptions),
        );
      },
    ),
  ],
);

class SubscriptionTrackerApp extends ConsumerWidget {
  const SubscriptionTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Subscription Tracker',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

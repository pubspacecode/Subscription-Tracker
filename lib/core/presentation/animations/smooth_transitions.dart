import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppTransitions {
  static PageTransitionsTheme get pageTransitionsTheme {
    return const PageTransitionsTheme(
      builders: {
        // Enforce "Slide Left/Right" on Android for a more premium/native feel
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }

  /// Custom Transition Page for Bottom-to-Top Slide (Modal effect)
  static CustomTransitionPage<T> slideUpPage<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero;         // End at center
        
        // Use a smoother curve (iOS-like sheet physics)
        const curve = Curves.fastLinearToSlowEaseIn;

        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Interval(0.0, 0.5, curve: Curves.easeOut))); // Fade in quickly

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500), // Slower for premium feel
      reverseTransitionDuration: const Duration(milliseconds: 500), // Match duration
    );
  }
}

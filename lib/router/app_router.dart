import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/capture_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/settings_screen.dart';
import '../main.dart';

CustomTransitionPage _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: onboardingDone ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadePage(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadePage(const HomeScreen(), state),
      ),
      GoRoute(
        path: '/capture',
        pageBuilder: (context, state) =>
            _slidePage(const CaptureScreen(), state),
      ),
      GoRoute(
        path: '/detail/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(DetailScreen(memoryId: id), state);
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _slidePage(const SettingsScreen(), state),
      ),
    ],
  );
});

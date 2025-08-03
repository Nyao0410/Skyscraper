import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/providers/session_provider.dart';
import 'package:skyscraper/screens/login_screen.dart';
import 'package:skyscraper/screens/main_shell.dart';
import 'package:skyscraper/screens/timeline_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/timeline',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          // TODO: Add other shell routes
        ],
      ),
    ],
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (session == null) {
        return loggingIn ? null : '/login';
      }

      if (loggingIn) {
        return '/timeline';
      }

      return null;
    },
  );
});
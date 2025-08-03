import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/providers/session_provider.dart';
import 'package:skyscraper/screens/create_post_screen.dart';
import 'package:skyscraper/screens/login_screen.dart';
import 'package:skyscraper/screens/main_shell.dart';
import 'package:skyscraper/screens/notifications_screen.dart';
import 'package:skyscraper/screens/profile_screen.dart';
import 'package:skyscraper/screens/search_screen.dart';
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
      GoRoute(
        path: '/create_post',
        parentNavigatorKey: _rootNavigatorKey, // This ensures it opens as a modal
        builder: (context, state) => const CreatePostScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
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

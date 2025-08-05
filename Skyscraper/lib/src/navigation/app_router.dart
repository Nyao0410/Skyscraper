import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/screens/create_post_screen.dart';
import 'package:skyscraper/src/screens/home_screen.dart';
import 'package:skyscraper/src/screens/login_screen.dart';
import 'package:skyscraper/src/screens/main_shell.dart';
import 'package:skyscraper/src/screens/notifications_screen.dart';
import 'package:skyscraper/src/screens/post_detail_screen.dart';
import 'package:skyscraper/src/screens/profile_screen.dart';
import 'package:skyscraper/src/screens/search_screen.dart';

part 'app_router.g.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provides the GoRouter instance for navigation.
@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/home', // 初期表示をホームに変更
    navigatorKey: _rootNavigatorKey,
    routes: [
      // メインの4画面（ボトムナビゲーションバーを持つ画面）
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
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
      // ボトムナビゲーションバーを持たない独立した画面
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        builder: (BuildContext context, GoRouterState state) =>
            PostDetailScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/create-post',
        // 全画面で表示するため、親Navigatorを使用
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
    ],
  );
}
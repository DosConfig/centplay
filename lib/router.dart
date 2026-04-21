import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/game_detail_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/chat_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoginRoute = state.uri.path == '/login';
    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
            path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: '/friends',
            builder: (context, state) => const FriendsScreen()),
        GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen()),
        GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/game/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: GameDetailScreen(id: state.pathParameters['id']!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/game/:id/play',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          WebViewScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/shop',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: '/chat/:friendUid',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ChatScreen(friendUid: state.pathParameters['friendUid']!),
    ),
  ],
);

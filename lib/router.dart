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
import 'screens/notifications_screen.dart';
import 'screens/controller_settings_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/video_feed_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

Widget _noTransition(
    BuildContext _, Animation<double> __, Animation<double> ___, Widget child) {
  return child;
}

Page<void> _noAnimationPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: _noTransition,
  );
}

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
          path: '/home',
          pageBuilder: (context, state) =>
              _noAnimationPage(const HomeScreen()),
        ),
        GoRoute(
          path: '/videos',
          pageBuilder: (context, state) =>
              _noAnimationPage(const VideoFeedScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              _noAnimationPage(const ProfileScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/game/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          GameDetailScreen(id: state.pathParameters['id']!),
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
      path: '/friends',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FriendsScreen(),
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: NotificationsScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: _noTransition,
      ),
    ),
    GoRoute(
      path: '/controller-settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ControllerSettingsScreen(),
    ),
    GoRoute(
      path: '/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          const LegalScreen(title: '이용약관', type: 'terms'),
    ),
    GoRoute(
      path: '/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          const LegalScreen(title: '개인정보 처리방침', type: 'privacy'),
    ),
    GoRoute(
      path: '/chat/:friendUid',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ChatScreen(friendUid: state.pathParameters['friendUid']!),
    ),
  ],
);

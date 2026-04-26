import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'router.dart';
import 'providers/theme_provider.dart';
import 'core/theme.dart';

class CentPlayApp extends ConsumerStatefulWidget {
  const CentPlayApp({super.key});

  @override
  ConsumerState<CentPlayApp> createState() => _CentPlayAppState();
}

class _CentPlayAppState extends ConsumerState<CentPlayApp> {
  @override
  void initState() {
    super.initState();
    _setupForegroundNotifications();
  }

  void _setupForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      final ctx = router.routerDelegate.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;

      final route = message.data['route'];

      ScaffoldMessenger.of(ctx).showMaterialBanner(
        MaterialBanner(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.title ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (notification.body != null) Text(notification.body!),
            ],
          ),
          leading: const Icon(Icons.notifications_active),
          actions: [
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(ctx).hideCurrentMaterialBanner(),
              child: const Text('닫기'),
            ),
            if (route != null)
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(ctx).hideCurrentMaterialBanner();
                  router.go(route);
                },
                child: const Text('보기'),
              ),
          ],
        ),
      );

      Future.delayed(const Duration(seconds: 4), () {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).hideCurrentMaterialBanner();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CentPlay',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../router.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init(String? uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (_) {
      // APNS token not available (e.g., iOS simulator)
    }
    if (uid != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    // Foreground messages → handled by onMessage stream in app
    // Background/terminated tap → deep link routing
    _setupNotificationTapHandlers();
  }

  void _setupNotificationTapHandlers() {
    // App was terminated, opened via notification tap
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTap(message);
    });

    // App was in background, opened via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && route is String && route.startsWith('/')) {
      router.go(route);
    }
  }

  /// Stream of foreground messages for UI to display
  static Stream<RemoteMessage> get onForegroundMessage {
    return FirebaseMessaging.onMessage;
  }
}

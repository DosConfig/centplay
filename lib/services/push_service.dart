import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init(String? uid) async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();

    if (uid != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground message — will be connected to UI snackbar
    });
  }
}

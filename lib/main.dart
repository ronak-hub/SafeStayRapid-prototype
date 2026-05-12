import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'widgets/firebase_connection_wrapper.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseInitError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    firebaseInitError = e;
    debugPrint('Firebase.initializeApp failed: $e\n$st');
  }

  if (firebaseInitError == null) {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('Notification permission: ${settings.authorizationStatus}');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message: ${message.notification?.title}');
      });

      final bool pushAllowed = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      // On web, requesting a token without permission throws permission-blocked.
      if (pushAllowed) {
        final String? fcmToken = kIsWeb
            ? await messaging.getToken(
                vapidKey:
                    'BPgcRY5LtHqmEHPsj0hVAE-g9zta6Po_37ZAUdwrdgLkHHckhn1xymmUx3jLudc2cKjxWZZfRLGmG_Y4pbaS7Ao',
              )
            : await messaging.getToken();
        debugPrint('FCM token: $fcmToken');
      } else {
        debugPrint(
          'Push not enabled (${settings.authorizationStatus.name}) — '
          'skipping FCM token. Reset site permissions in the browser if needed.',
        );
      }
    } catch (e, st) {
      debugPrint('FCM setup (optional): $e\n$st');
    }
  }

  runApp(MyApp(firebaseInitError: firebaseInitError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseInitError});

  final Object? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeStay Rapid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return FirebaseConnectionWrapper(
          firebaseInitError: firebaseInitError,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

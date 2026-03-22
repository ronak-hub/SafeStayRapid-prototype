// ignore_for_file: avoid_print  // For debugging only - remove in production

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This is called when app is in background or terminated
  print("Background/terminated message received: ${message.notification?.title}");
  // Add any background logic here (e.g., show local notification)
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDPYUKUoLrjGyxIYUWTjMd8Wl-ilz2VkbM",
        authDomain: "safestay-rapid-5c29e.firebaseapp.com",
        projectId: "safestay-rapid-5c29e",
        storageBucket: "safestay-rapid-5c29e.firebasestorage.app",
        messagingSenderId: "34147668629",
        appId: "1:34147668629:web:d88637bfaab24a7304819c",
        measurementId: "G-H61V42T2BH",
      ),
    );

    // Initialize FCM
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (required for iOS, recommended for Android/web)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Register background handler (for when app is closed/minimized)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      // Optional: show in-app snackbar or dialog here
    });

    // Get FCM token with VAPID key for web push
    String? fcmToken = await messaging.getToken(
      vapidKey: "BPgcRY5LtHqmEHPsj0hVAE-g9zta6Po_37ZAUdwrdgLkHHckhn1xymmUx3jLudc2cKjxWZZfRLGmG_Y4pbaS7Ao",
    );
    print("FCM Token: $fcmToken");

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("Notifications denied – push features will be limited");
    }

  } catch (e) {
    print("FCM initialization failed (app continues without push): $e");
    // Do NOT rethrow — allow app to run normally
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeStay Rapid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
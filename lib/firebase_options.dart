// Firebase options for this project (web + Android registered in Firebase Console).
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Web and Android. '
          'Add an iOS (or other) app in Firebase Console and run FlutterFire CLI.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDPYUKUoLrjGyxIYUWTjMd8Wl-ilz2VkbM',
    appId: '1:34147668629:web:d88637bfaab24a7304819c',
    messagingSenderId: '34147668629',
    projectId: 'safestay-rapid-5c29e',
    authDomain: 'safestay-rapid-5c29e.firebaseapp.com',
    storageBucket: 'safestay-rapid-5c29e.firebasestorage.app',
    measurementId: 'G-H61V42T2BH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsrTGapMZ8B1abl5SDZGJTSeEcbufwidE',
    appId: '1:34147668629:android:5278065d218832e004819c',
    messagingSenderId: '34147668629',
    projectId: 'safestay-rapid-5c29e',
    storageBucket: 'safestay-rapid-5c29e.firebasestorage.app',
  );
}

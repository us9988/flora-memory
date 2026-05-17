import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured yet');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCG8dk5_a3IXt49776DsDZmPM0O-k31dbA',
    appId: '1:1042012511298:android:82f606ad22b3b0f08061db',
    messagingSenderId: '1042012511298',
    projectId: 'myflora-97ee7',
    storageBucket: 'myflora-97ee7.firebasestorage.app',
  );
}

// Generated from google-services.json and Firebase web config.
// Do NOT commit service account keys here — only public client-side values.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS Firebase config not yet added.');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}');
    }
  }

  // Values from frontend/src/firebase.js (web app)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAX3Iw8m-ax9o5hbLXlXcoz8hvbWRloQqI',
    appId: '1:604608810400:web:37d3c13625eb963018e8c5',
    messagingSenderId: '604608810400',
    projectId: 'finsense-finance-app',
    authDomain: 'finsense-finance-app.firebaseapp.com',
    storageBucket: 'finsense-finance-app.firebasestorage.app',
    measurementId: 'G-ZKCXBVNMFY',
  );

  // Values from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZrB9V7eHHQKP5LWXjoUKRpJJskaZ21Jw',
    appId: '1:604608810400:android:92aeffb2c648ff5518e8c5',
    messagingSenderId: '604608810400',
    projectId: 'finsense-finance-app',
    storageBucket: 'finsense-finance-app.firebasestorage.app',
  );
}

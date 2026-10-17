import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjb0Wg20mjQVYIwhtH-BJshG1EQe0DrhU',
    appId: '1:472143225007:android:8b53665b5aa53699b0345a',
    messagingSenderId: '472143225007',
    projectId: 'rent-managment-8d9c8',
    storageBucket: 'rent-managment-8d9c8.firebasestorage.app',
  );
}

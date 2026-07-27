import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder Firebase options for coursework scaffolding.
///
/// Replace this file with the real output of:
/// flutterfire configure --out=lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'replace-with-web-api-key',
    appId: 'replace-with-web-app-id',
    messagingSenderId: 'replace-with-sender-id',
    projectId: 'fittrack-coursework',
    authDomain: 'fittrack-coursework.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'replace-with-android-api-key',
    appId: 'replace-with-android-app-id',
    messagingSenderId: 'replace-with-sender-id',
    projectId: 'fittrack-coursework',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'replace-with-ios-api-key',
    appId: 'replace-with-ios-app-id',
    messagingSenderId: 'replace-with-sender-id',
    projectId: 'fittrack-coursework',
    iosBundleId: 'com.fittrack.mobile',
  );
}

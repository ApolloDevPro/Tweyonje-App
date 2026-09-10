import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the Tweyonje app.
///
/// The `flutterfire configure` CLI normally generates this file automatically.
/// Until then, fill in your own values from the Firebase console:
///
/// Project settings > Your apps:
///  - Web app:  the `firebaseConfig` JS object -> [web]
///  - Android app (`ug.tweyonje.tweyonje`): google-services.json -> [android]
///  - iOS app (`ug.tweyonje.tweyonje`): GoogleService-Info.plist -> [ios]
///
/// Only the configs for the platforms you actually ship need to be filled in;
/// empty platforms make [currentPlatform] throw so the caller can treat
/// push notifications as an optional no-op.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCYab7dFMw_UR9gk4mg0H9YHlqMvsPt0rE',
    appId: '1:427328126917:web:ce354d2e5a83e07a0c15ac',
    messagingSenderId: '427328126917',
    projectId: 'tweyonje-8f1ea',
    authDomain: 'tweyonje-8f1ea.firebaseapp.com',
    storageBucket: 'tweyonje-8f1ea.firebasestorage.app',
    measurementId: 'G-8WKBNMXY4Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'ug.tweyonje.tweyonje',
  );
}

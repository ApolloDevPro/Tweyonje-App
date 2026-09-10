import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// No-op web implementation of [FirebaseMessagingPlatform].
///
/// Web push messaging on this app is intentionally disabled at the Flutter
/// level; browser push is handled by the Firebase web SDK service worker
/// (`web/firebase-messaging-sw.js`). This class exists only so the generated
/// Flutter web plugin registrant compiles, because the real
/// `firebase_messaging_web` interop does not compile against the current
/// Flutter web SDK.
class FirebaseMessagingWeb extends FirebaseMessagingPlatform {
  FirebaseMessagingWeb() : super();

  static void registerWith(Registrar registrar) {
    FirebaseMessagingPlatform.instance = FirebaseMessagingWeb();
  }
}
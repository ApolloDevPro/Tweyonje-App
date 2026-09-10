import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web no-op implementation of push notifications.
///
/// Web push messaging is handled by the Firebase web SDK loaded in
/// `web/index.html` and the `web/firebase-messaging-sw.js` service worker.
/// The Flutter `firebase_messaging` web implementation is intentionally not
/// imported so its incompatible web interop is never compiled.
class PushNotificationService {
  const PushNotificationService();

  Future<void> initialize() async {}

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}

  Future<String?> getToken() async => null;

  Future<void> deleteToken() async {}
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return const PushNotificationService();
});
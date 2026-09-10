import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_handler.dart';

/// Initialize Firebase Cloud Messaging and notification handlers
Future<void> initializeNotifications(WidgetRef ref) async {
  try {
    // Request permission for iOS
    NotificationSettings settings = 
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✓ Notification permission granted');

      // Get FCM token
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('✓ FCM Token: $token');
        // TODO: Save token to backend
        // await ref.read(storageServiceProvider).saveFCMToken(token);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('✓ FCM Token refreshed: $newToken');
        // TODO: Update token on backend
      });

      // Initialize notification handler for deep linking
      final notificationHandler = ref.read(notificationHandlerProvider);
      await notificationHandler.initialize();
      
      debugPrint('✓ Notification handlers initialized');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠ Notification permission denied');
    } else {
      debugPrint('⚠ Notification permission not determined');
    }
  } catch (e) {
    debugPrint('✗ Failed to initialize notifications: $e');
    // Don't crash the app if notifications fail
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
  // Handle background message if needed
}

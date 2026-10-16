import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_controllers.dart';
import '../storage/storage_service.dart';
import 'api_client.dart';
import 'logger.dart';

/// Publishes a typed [AppEventType] on [appEventBusProvider] so connected
/// screens refresh the moment an FCM message arrives. Falls back to nothing on
/// web, where pure-web push is handled by the service worker.
void _publish(Ref ref, RemoteMessage message) {
  final data = message.data;
  final type = data['type'] ?? 'general';
  final event = switch (type) {
    'collection_update' => AppEventType.collectionCompleted,
    'payment_update' => AppEventType.paymentCompleted,
    'location_update' => AppEventType.assignmentUpdated,
    'reward_update' => AppEventType.requestUpdated,
    _ => AppEventType.notificationAdded,
  };
  ref
      .read(appEventBusProvider)
      .publish(
        event,
        id: data['request_id'] ?? data['id'],
        message: message.notification?.body,
      );
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StorageService _storageService;
  final ApiClient _apiClient;
  final Ref _ref;

  PushNotificationService(this._storageService, this._apiClient, this._ref);

  Future<void> initialize() async {
    try {
      // Initialize Firebase if a config is available; on unsupported
      // platforms/without a firebase config this throws and the caller treats
      // push notifications as an optional no-op.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      Logger.info('Firebase initialized');

      // Request notification permissions
      await _requestPermissions();

      // Get initial message if app was opened from notification
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Get and register FCM token
      await _registerFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      Logger.info('Push notification service initialized');
    } catch (e) {
      Logger.error('Failed to initialize push notification service', error: e);
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger.info('Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      Logger.warning('Provisional notification permissions granted');
    } else {
      Logger.warning('Notification permissions denied');
    }
  }

  Future<void> _registerFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // Save token locally
        await _storageService.saveFCMToken(token);

        // Send token to backend
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      Logger.error('Failed to register FCM token', error: e);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _apiClient.registerDevice(token);
      Logger.info('FCM token registered with backend');
    } catch (e) {
      Logger.error('Failed to send FCM token to backend', error: e);
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    Logger.info('FCM token refreshed');

    // Save new token locally
    await _storageService.saveFCMToken(newToken);

    // Send new token to backend
    await _sendTokenToBackend(newToken);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('Received foreground message: ${message.notification?.title}');
    _publish(_ref, message);
    _handleMessage(message);
  }

  void _handleMessage(RemoteMessage message) {
    Logger.info('Handling message: ${message.data}');

    // Extract message data
    final title = message.notification?.title ?? 'Tweyonje';
    final body = message.notification?.body ?? '';
    final data = message.data;

    // Handle different notification types
    final notificationType = data['type'] ?? 'general';

    switch (notificationType) {
      case 'collection_update':
        _handleCollectionUpdate(data);
        break;
      case 'payment_update':
        _handlePaymentUpdate(data);
        break;
      case 'location_update':
        _handleLocationUpdate(data);
        break;
      case 'reward_update':
        _handleRewardUpdate(data);
        break;
      default:
        _handleGeneralNotification(title, body, data);
    }
  }

  void _handleCollectionUpdate(Map<String, dynamic> data) {
    Logger.info('Collection update notification received');
  }

  void _handlePaymentUpdate(Map<String, dynamic> data) {
    Logger.info('Payment update notification received');
  }

  void _handleLocationUpdate(Map<String, dynamic> data) {
    Logger.info('Location update notification received');
  }

  void _handleRewardUpdate(Map<String, dynamic> data) {
    Logger.info('Reward update notification received');
  }

  void _handleGeneralNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    Logger.info('General notification: $title - $body');
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.info('Subscribed to topic: $topic');
    } catch (e) {
      Logger.error('Failed to subscribe to topic: $topic', error: e);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      Logger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      Logger.error('Failed to unsubscribe from topic: $topic', error: e);
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      Logger.info('FCM token deleted');
    } catch (e) {
      Logger.error('Failed to delete FCM token', error: e);
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final storageService = ref.watch(storageServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return PushNotificationService(storageService, apiClient, ref);
});

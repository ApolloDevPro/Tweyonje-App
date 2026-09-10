import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../routing/app_router.dart';

final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  final router = ref.watch(routerProvider);
  return NotificationHandler(router);
});

/// Handles push notification deep linking and routing
class NotificationHandler {
  final GoRouter router;

  NotificationHandler(this.router);

  /// Initialize notification handlers
  Future<void> initialize() async {
    // Handle notification when app is terminated and opened via notification
    RemoteMessage? initialMessage = 
        await FirebaseMessaging.instance.getInitialMessage();
    
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }

    // Handle notification when app is in background and user taps it
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);

    // Handle notification when app is in foreground (optional - show in-app notification)
    FirebaseMessaging.onMessage.listen(_handleForegroundNotification);
  }

  /// Handle navigation based on notification type
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    if (type == null) {
      // No type specified, go to notifications screen
      router.go('/notifications');
      return;
    }

    // Route based on notification type
    switch (type) {
      case 'collection_update':
      case 'collection_complete':
      case 'collection_delayed':
      case 'collection_late_start':
        _navigateToRequest(data['request_id']);
        break;

      case 'assignment_update':
        _navigateToAssignment(data['assignment_id']);
        break;

      case 'payment_update':
      case 'payment_complete':
        _navigateToPayment(data['payment_id']);
        break;

      case 'chat_message':
        _navigateToChat(data['conversation_id']);
        break;

      case 'ticket_escalated':
      case 'ticket_escalated_assigned':
      case 'ticket_resolved':
        _navigateToTicket(data['ticket_id']);
        break;

      case 'recycling_offer':
        router.go('/recycling');
        break;

      case 'location_update':
        _navigateToTracking(data['assignment_id']);
        break;

      default:
        // Unknown type, go to notifications
        router.go('/notifications');
    }
  }

  /// Handle foreground notifications (show in-app)
  void _handleForegroundNotification(RemoteMessage message) {
    // This is handled by the app's notification provider
    // You can show a snackbar or in-app notification here
    debugPrint('Foreground notification: ${message.notification?.title}');
  }

  void _navigateToRequest(String? requestId) {
    if (requestId != null) {
      router.go('/request-detail/$requestId');
    } else {
      router.go('/my-requests');
    }
  }

  void _navigateToAssignment(String? assignmentId) {
    if (assignmentId != null) {
      router.go('/collector-job/$assignmentId');
    } else {
      router.go('/collector');
    }
  }

  void _navigateToPayment(String? paymentId) {
    if (paymentId != null) {
      router.go('/payment-history');
    } else {
      router.go('/payment');
    }
  }

  void _navigateToChat(String? conversationId) {
    if (conversationId != null) {
      router.go('/chat/$conversationId');
    } else {
      router.go('/chat');
    }
  }

  void _navigateToTicket(String? ticketId) {
    if (ticketId != null) {
      router.go('/support/$ticketId');
    } else {
      router.go('/support');
    }
  }

  void _navigateToTracking(String? assignmentId) {
    if (assignmentId != null) {
      router.go('/tracking/$assignmentId');
    } else {
      router.go('/');
    }
  }
}



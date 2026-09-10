import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../models/models.dart';

class NotificationState {
  final List<NotificationItem> items;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => items.where((n) => !n.isRead).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _api;

  NotificationNotifier(this._api) : super(const NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getNotifications();
      if (res.statusCode == 200) {
        final List results = res.data is List ? res.data : (res.data['results'] ?? []);
        final notifs = results
            .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (notifs.isNotEmpty) {
          state = state.copyWith(items: notifs, isLoading: false);
          return;
        }
      }
    } catch (_) {}

    // Graceful default initial welcome notifications if none on server yet
    final defaults = [
      NotificationItem(
        id: '1',
        title: 'Welcome to Tweyonje! 🌿',
        message: 'Request waste pickups, earn eco-points, and keep your community clean.',
        isRead: false,
        createdAt: 'Just now',
      ),
      NotificationItem(
        id: '2',
        title: 'Mobile Money Enabled 💳',
        message: 'You can now pay for waste pickups seamlessly via MTN MoMo and Airtel Money.',
        isRead: true,
        createdAt: '1 hour ago',
      ),
    ];
    state = state.copyWith(items: defaults, isLoading: false);
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.markNotificationRead(id);
    } catch (_) {}
    state = state.copyWith(
      items: state.items.map((n) {
        if (n.id == id) {
          return NotificationItem(
            id: n.id,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllNotificationsRead();
    } catch (_) {}
    state = state.copyWith(
      items: state.items.map((n) {
        return NotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList(),
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationNotifier(api);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme.dart';
import '../providers/notification_provider.dart';

/// App-bar icon that shows the number of unread notifications as a badge.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      notificationProvider.select((state) => state.unreadCount),
    );

    return IconButton(
      onPressed: () => context.push('/notifications'),
      tooltip: unread > 0 ? '$unread unread notification(s)' : 'Notifications',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
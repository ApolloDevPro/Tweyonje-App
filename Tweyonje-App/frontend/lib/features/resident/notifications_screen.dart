import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          notifState.unreadCount > 0
              ? 'Notifications (${notifState.unreadCount})'
              : 'Notifications',
        ),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: RefreshIndicator(
        onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
        child: notifState.isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No notifications yet', style: AppTypography.h4),
                        const SizedBox(height: 4),
                        Text('We will alert you when collectors arrive or rewards are credited.', style: AppTypography.caption),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return InkWell(
                        onTap: notif.isRead
                            ? null
                            : () => ref.read(notificationProvider.notifier).markAsRead(notif.id),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: AppCard(
                          color: notif.isRead ? AppColors.surface : AppColors.primarySoft.withAlpha(102),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: notif.isRead ? AppColors.surfaceVariant : AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  color: notif.isRead ? AppColors.textSecondary : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        if (notif.createdAt != null)
                                          Text(
                                            notif.createdAt!,
                                            style: AppTypography.caption,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
},
                  ),
          ),
        ),
      ),
    );
  }
}

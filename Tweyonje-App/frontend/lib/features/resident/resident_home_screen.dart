import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../widgets/widgets.dart';

class ResidentHomeScreen extends ConsumerWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final requestsAsync = ref.watch(wasteRequestsProvider);
    final rewardsAsync = ref.watch(rewardsStatusProvider);

    final balance = rewardsAsync.valueOrNull?.balance ?? 0;
    final requests = requestsAsync.valueOrNull ?? const [];
    final firstName = user?.fullName.split(' ').first ?? 'Neighbour';

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Home', style: AppTypography.h4),
            Text('Tweyonje smart waste', style: AppTypography.caption),
          ],
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      destinations: _destinations(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(wasteRequestsProvider.notifier).fetchRequests();
          ref.invalidate(rewardsStatusProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: ResponsiveContent(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHero(
                gradient: AppGradients.primary,
                icon: Icons.eco_rounded,
                overline: 'WELCOME BACK',
                title: 'Hello, $firstName 👋',
                subtitle: 'Let’s keep Uganda clean today',
                trailing: HeroPill(
                  icon: Icons.stars_rounded,
                  label: '$balance pts',
                  color: AppColors.primaryDark,
                  onTap: () => context.push('/rewards'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ResponsiveWrap(
                minItemWidth: 150,
                children: [
                  MetricTile(
                    icon: Icons.inbox_outlined,
                    value: '${requests.length}',
                    label: 'Active Requests',
                    color: AppColors.primary,
                  ),
                  MetricTile(
                    icon: Icons.recycling_outlined,
                    value: '$balance',
                    label: 'Eco-Points',
                    color: AppColors.accentDark,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              const SectionHeader(title: 'Quick Services'),
              const SizedBox(height: AppSpacing.md),

              ResponsiveWrap(
                minItemWidth: 150,
                children: [
                  _QuickActionCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Request Pickup',
                    color: AppColors.primary,
                    onTap: () => context.push('/create-request'),
                  ),
                  _QuickActionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'AI Classifier',
                    color: AppColors.info,
                    onTap: () => context.push('/waste-classify'),
                  ),
                  _QuickActionCard(
                    icon: Icons.report_problem_outlined,
                    title: 'Report Dumping',
                    color: AppColors.danger,
                    onTap: () => context.push('/reports'),
                  ),
                  _QuickActionCard(
                    icon: Icons.storefront_outlined,
                    title: 'Recycling',
                    color: AppColors.accentDark,
                    onTap: () => context.push('/recycling'),
                  ),
                  _QuickActionCard(
                    icon: Icons.event_repeat_outlined,
                    title: 'Schedules',
                    color: AppColors.info,
                    onTap: () => context.push('/schedules'),
                  ),
                  _QuickActionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Payments',
                    color: AppColors.primary,
                    onTap: () => context.push('/payment-history'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              const SectionHeader(title: 'Support & Account'),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.info,
                      ),
                      title: const Text('Chat with Partner'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/chat'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.star_outline_rounded,
                        color: AppColors.accentDark,
                      ),
                      title: const Text('Rate a Collector'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/ratings'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.headset_mic_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Help & Support'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/support'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                      ),
                      title: const Text('Settings'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              SectionHeader(
                title: 'Active Requests',
                actionLabel: 'View All',
                onAction: () => context.push('/my-requests'),
              ),
              const SizedBox(height: AppSpacing.md),

              requestsAsync.when(
                data: (allRequests) {
                  if (allRequests.isEmpty) {
                    return EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No Active Requests',
                      description:
                          'Need waste picked up from your home or business?',
                      actionText: 'Request Collection',
                      onAction: () => context.push('/create-request'),
                    );
                  }

                  return ResponsiveWrap(
                    minItemWidth: 340,
                    children: allRequests.take(5).map((req) {
                      return _RequestCard(
                        request: req,
                        onTap: () => context.push(
                          '/request-detail/${req.id}',
                          extra: req,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) =>
                    Center(child: Text('Error loading requests: $err')),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

List<ResponsiveDestination> _destinations(BuildContext context) => [
      const ResponsiveDestination(
        icon: Icons.home_outlined,
        label: 'Home',
      ),
      ResponsiveDestination(
        icon: Icons.inbox_outlined,
        label: 'My Requests',
        onTap: () => context.push('/my-requests'),
      ),
      ResponsiveDestination(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        onTap: () => context.push('/notifications'),
      ),
      ResponsiveDestination(
        icon: Icons.receipt_long_outlined,
        label: 'Payments',
        onTap: () => context.push('/payment-history'),
      ),
      ResponsiveDestination(
        icon: Icons.event_repeat_outlined,
        label: 'Schedules',
        onTap: () => context.push('/schedules'),
      ),
      ResponsiveDestination(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        onTap: () => context.push('/chat'),
      ),
      ResponsiveDestination(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => context.push('/settings'),
      ),
    ];

class _RequestCard extends StatelessWidget {
  final WasteRequest request;
  final VoidCallback? onTap;

  const _RequestCard({required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = statusVisual(request.status);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request.categoryDetails?.name ?? 'Waste Request',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(status: request.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.pickupAddress,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${request.estimatedWeightKg} kg • UGX ${request.estimatedPrice.toStringAsFixed(0)}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withAlpha(140)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import 'app_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveIconColor.withAlpha(24),
                  effectiveIconColor.withAlpha(12),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 56,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Title
          Text(
            title,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Subtitle
          Text(
            subtitle,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Action button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class NoDataEmptyState extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NoDataEmptyState({
    super.key,
    this.title = 'No data available',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inbox_outlined,
      title: title,
      subtitle: 'There\'s no data to display at the moment. Check back later or add some data to get started.',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class NoRequestsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateRequest;

  const NoRequestsEmptyState({super.key, this.onCreateRequest});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.delete_outline,
      title: 'No waste requests yet',
      subtitle: 'You haven\'t made any waste collection requests. Start by creating your first request to schedule a pickup.',
      actionLabel: 'Create Request',
      onAction: onCreateRequest,
      iconColor: AppColors.info,
    );
  }
}

class NoNotificationsEmptyState extends StatelessWidget {
  const NoNotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.notifications_none,
      title: 'No notifications',
      subtitle: 'You\'re all caught up! We\'ll notify you when there\'s something important.',
      iconColor: AppColors.warning,
    );
  }
}

class NoReportsEmptyState extends StatelessWidget {
  final VoidCallback? onReportIssue;

  const NoReportsEmptyState({super.key, this.onReportIssue});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.report_outlined,
      title: 'No reports submitted',
      subtitle: 'Help keep Uganda clean by reporting illegal dumping sites in your area.',
      actionLabel: 'Report Issue',
      onAction: onReportIssue,
      iconColor: AppColors.danger,
    );
  }
}

class NoRewardsEmptyState extends StatelessWidget {
  const NoRewardsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.card_giftcard_outlined,
      title: 'No rewards yet',
      subtitle: 'Start recycling and disposing of waste responsibly to earn eco-points and unlock rewards.',
      iconColor: AppColors.success,
    );
  }
}

class NoUsersEmptyState extends StatelessWidget {
  final VoidCallback? onAddUser;

  const NoUsersEmptyState({super.key, this.onAddUser});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No users yet',
      subtitle: 'Create your first user account to get started with the platform.',
      actionLabel: 'Add User',
      onAction: onAddUser,
    );
  }
}

class NoVerificationsEmptyState extends StatelessWidget {
  const NoVerificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.verified_user_outlined,
      title: 'No pending verifications',
      subtitle: 'All collector verifications are up to date. Great job keeping the platform secure!',
      iconColor: AppColors.success,
    );
  }
}

class NoZonesEmptyState extends StatelessWidget {
  final VoidCallback? onAddZone;

  const NoZonesEmptyState({super.key, this.onAddZone});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.map_outlined,
      title: 'No zones configured',
      subtitle: 'Add zones to organize waste collection by geographical areas.',
      actionLabel: 'Add Zone',
      onAction: onAddZone,
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const SearchEmptyState({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No results found',
      subtitle: 'We couldn\'t find anything matching "$searchQuery". Try different keywords or clear your search.',
      actionLabel: 'Clear Search',
      onAction: onClearSearch,
      iconColor: AppColors.textSecondary,
    );
  }
}

class NetworkErrorEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorEmptyState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'No internet connection',
      subtitle: 'Please check your internet connection and try again to load the content.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: AppColors.warning,
    );
  }
}

class ServerErrorEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorEmptyState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.cloud_off,
      title: 'Server unavailable',
      subtitle: 'Our servers are experiencing issues. Please try again later.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: AppColors.danger,
    );
  }
}

class PermissionEmptyState extends StatelessWidget {
  const PermissionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.block,
      title: 'Access denied',
      subtitle: 'You don\'t have permission to access this content. Please contact your administrator if you think this is an error.',
      iconColor: AppColors.danger,
    );
  }
}

class MaintenanceEmptyState extends StatelessWidget {
  const MaintenanceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.build,
      title: 'Under maintenance',
      subtitle: 'We\'re performing scheduled maintenance. Please check back soon.',
      iconColor: AppColors.info,
    );
  }
}

class OnboardingEmptyState extends StatelessWidget {
  final VoidCallback? onGetStarted;

  const OnboardingEmptyState({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.recycling,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Welcome text
          Text(
            'Welcome to Tweyonje',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          Text(
            'Together for a Cleaner Uganda',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Features
          _FeatureItem(
            icon: Icons.delete_outline,
            title: 'Easy Waste Collection',
            description: 'Schedule pickups with just a few taps',
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.recycling,
            title: 'Earn Rewards',
            description: 'Get eco-points for responsible disposal',
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.map,
            title: 'Track Progress',
            description: 'See your environmental impact',
          ),
          const SizedBox(height: AppSpacing.xl),
          
          if (onGetStarted != null)
            AppButton(
              text: 'Get Started',
              icon: const Icon(Icons.arrow_forward, size: 16),
              onPressed: onGetStarted,
            ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(24),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

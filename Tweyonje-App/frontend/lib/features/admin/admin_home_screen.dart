import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';
import 'role_meta.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final usersAsync = ref.watch(adminUsersProvider);
    final users = usersAsync.valueOrNull ?? <User>[];

    void refresh() {
      ref.invalidate(adminUsersProvider);
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: AppTypography.h4),
            Text(
              user?.fullName ?? 'Administrator',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: refresh),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      destinations: _destinations(context),
      body: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            DashboardHero(
              gradient: AppGradients.primary,
              icon: Icons.admin_panel_settings_rounded,
              overline: 'PLATFORM ADMIN',
              title: 'Admin Console',
              subtitle: 'Create and manage team accounts across all roles.',
              trailing: HeroPill(
                icon: Icons.people_outline_rounded,
                label: '${users.length}',
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Create New Account',
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              onPressed: () => context.push('/admin/create-account'),
            ),
            const SizedBox(height: AppSpacing.md),
            ResponsiveWrap(
              minItemWidth: 220,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin/analytics'),
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: const Text('Analytics'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin/zones'),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Zones'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            ResponsiveWrap(
              minItemWidth: 150,
              children: [
                MetricTile(
                  icon: Icons.group_outlined,
                  value: '${users.length}',
                  label: 'Total Accounts',
                  color: AppColors.primary,
                ),
                MetricTile(
                  icon: Icons.local_shipping_outlined,
                  value: users
                      .where((u) => u.role == UserRole.collector)
                      .length
                      .toString(),
                  label: 'Collectors',
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            SectionHeader(
              title: 'Team Accounts',
              subtitle: 'All registered users',
              actionLabel: 'Refresh',
              onAction: refresh,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (usersAsync.isLoading && users.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (users.isEmpty)
              _EmptyAccounts()
            else
              ...users.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _UserTile(user: u),
                ),
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
        icon: Icons.insights_outlined,
        label: 'Analytics',
        onTap: () => context.push('/admin/analytics'),
      ),
      ResponsiveDestination(
        icon: Icons.map_outlined,
        label: 'Zones',
        onTap: () => context.push('/admin/zones'),
      ),
      ResponsiveDestination(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Create Account',
        onTap: () => context.push('/admin/create-account'),
      ),
    ];

class _UserTile extends StatelessWidget {
  final User user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final meta = roleMeta(user.role);
    final initial =
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: meta.color.withAlpha(24),
            child: Text(
              initial,
              style: AppTypography.h4.copyWith(color: meta.color),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? '—' : user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _RoleChip(meta: meta),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final RoleMeta meta;

  const _RoleChip({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: meta.color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 14, color: meta.color),
          const SizedBox(width: 4),
          Text(
            meta.label,
            style: AppTypography.labelSmall.copyWith(
              color: meta.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No accounts yet',
            style: AppTypography.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first account to get started.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
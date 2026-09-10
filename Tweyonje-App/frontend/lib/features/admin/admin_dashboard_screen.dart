import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<AdminNavItem> _navItems = const [
    AdminNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/admin/dashboard',
    ),
    AdminNavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Users',
      route: '/admin/users',
    ),
    AdminNavItem(
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user,
      label: 'Verifications',
      route: '/admin/verifications',
    ),
    AdminNavItem(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
      label: 'Zones',
      route: '/admin/zones',
    ),
    AdminNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: '/admin/settings',
    ),
    AdminNavItem(
      icon: Icons.policy_outlined,
      selectedIcon: Icons.policy,
      label: 'Privacy Policy',
      route: '/admin/privacy-policy',
    ),
    AdminNavItem(
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
      label: 'Export Data',
      route: '/admin/data-export',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Navigation Sidebar
          _buildSidebar(user),
          // Main Content
          Expanded(
            child: _buildContent(dashboardAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(User? user) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.recycling,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tweyonje',
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Admin Console',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return _buildNavItem(item, isSelected, index);
              },
            ),
          ),
          // User Profile
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withAlpha(24),
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : 'A',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Admin',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => _handleLogout(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(AdminNavItem item, bool isSelected, int index) {
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        context.push(item.route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              item.label,
              style: AppTypography.body.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AsyncValue<AdminDashboardData> dashboardAsync) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _navItems[_selectedIndex].label,
          style: AppTypography.h4,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        child: dashboardAsync.when(
          data: (data) => _buildDashboardContent(data),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load dashboard',
                  style: AppTypography.h5,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(AdminDashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(),
          const SizedBox(height: AppSpacing.xl),

          // Quick Stats
          _buildQuickStats(data),
          const SizedBox(height: AppSpacing.xl),

          // Charts and Detailed Metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildUsersSection(data),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildActivitySection(data),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Waste Requests Section
          _buildWasteRequestsSection(data),
          const SizedBox(height: AppSpacing.xl),

          // Financial Overview
          _buildFinancialSection(data),
          const SizedBox(height: AppSpacing.xl),

          // Pending Verifications Alert
          if (data.verifications.pending > 0)
            _buildVerificationsAlert(data),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = ref.watch(authProvider).user;
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
    if (hour >= 17) greeting = 'Good evening';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${user?.fullName ?? 'Admin'}!',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s what\'s happening with Tweyonje today.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            text: 'Create Account',
            icon: const Icon(Icons.person_add, size: 16),
            onPressed: () => context.push('/admin/create-account'),
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AdminDashboardData data) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: const [
        _StatCard(
          icon: Icons.people,
          label: 'Total Users',
          value: '0',
          change: '+0 this week',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.delete_outline,
          label: 'Waste Requests',
          value: '0',
          change: '0 pending',
          color: AppColors.info,
        ),
        _StatCard(
          icon: Icons.verified_user,
          label: 'Verifications',
          value: '0',
          change: 'pending approval',
          color: AppColors.warning,
        ),
        _StatCard(
          icon: Icons.attach_money,
          label: 'Revenue',
          value: '0',
          change: 'UGX',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildUsersSection(AdminDashboardData data) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Users by Role',
            subtitle: 'Distribution across platform',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildActivitySection(AdminDashboardData data) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Activity',
            subtitle: 'Latest platform events',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ActivityItem(
            icon: Icons.person_add,
            title: '0 new users',
            subtitle: 'Joined this week',
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          const _ActivityItem(
            icon: Icons.delete,
            title: '0 new requests',
            subtitle: 'Created this week',
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.md),
          const _ActivityItem(
            icon: Icons.report,
            title: '0 new reports',
            subtitle: 'Submitted this week',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildWasteRequestsSection(AdminDashboardData data) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Waste Collection Overview',
            subtitle: 'Request status and volume',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(
                child: _MetricTile(
                  icon: Icons.pending,
                  label: 'Pending',
                  value: '0',
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  icon: Icons.local_shipping,
                  label: 'In Progress',
                  value: '0',
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: '0',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  icon: Icons.scale,
                  label: 'Total Weight',
                  value: '0t',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(AdminDashboardData data) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Financial Overview',
            subtitle: 'Revenue and payouts',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(
                child: _MetricTile(
                  icon: Icons.trending_up,
                  label: 'Total Revenue',
                  value: '0',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  icon: Icons.payments,
                  label: 'Total Payouts',
                  value: '0',
                  color: AppColors.danger,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  icon: Icons.account_balance_wallet,
                  label: 'Net Margin',
                  value: '0',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsAlert(AdminDashboardData data) {
    return const SizedBox.shrink();
  }

  void _handleLogout() {
    ref.read(authProvider.notifier).logout();
    context.go('/login');
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                change,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(24),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
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
                subtitle,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

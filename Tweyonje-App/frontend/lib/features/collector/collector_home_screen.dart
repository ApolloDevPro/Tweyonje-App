import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collector_provider.dart';
import '../../widgets/widgets.dart';

class CollectorHomeScreen extends ConsumerWidget {
  const CollectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final dashboardAsync = ref.watch(collectorDashboardProvider);

    final firstName = user?.fullName.split(' ').first ?? 'Collector';

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collector Console', style: AppTypography.h4),
            Text(user?.fullName ?? 'Operator', style: AppTypography.caption),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      destinations: _destinations(context),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(collectorDashboardProvider.notifier).fetchDashboard(),
        child: dashboardAsync.when(
          data: (data) {
            final active = data?.activeShift ?? false;
            final jobs = data?.jobs ?? const [];

            return SingleChildScrollView(
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
                    gradient: AppGradients.accent,
                    icon: Icons.local_shipping_rounded,
                    overline: 'COLLECTOR CONSOLE',
                    title: 'Hello, $firstName 👋',
                    subtitle: active
                        ? 'Shift active · GPS tracking enabled'
                        : 'Start your shift to receive pickup jobs',
                    trailing: HeroPill(
                      icon: active
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_fill_rounded,
                      label: active ? 'End Shift' : 'Start Shift',
                      color: active ? AppColors.danger : AppColors.primary,
                      onTap: () async {
                        if (active) {
                          await ref
                              .read(collectorDashboardProvider.notifier)
                              .endShift('current');
                        } else {
                          await ref
                              .read(collectorDashboardProvider.notifier)
                              .startShift();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  ResponsiveWrap(
                    minItemWidth: 150,
                    children: [
                      MetricTile(
                        icon: Icons.assignment_outlined,
                        value: '${data?.todayTotal ?? 0}',
                        label: 'Assigned Jobs',
                        color: AppColors.info,
                      ),
                      MetricTile(
                        icon: Icons.task_alt_outlined,
                        value: '${data?.todayCompleted ?? 0}',
                        label: 'Completed',
                        color: AppColors.success,
                      ),
                      MetricTile(
                        icon: Icons.scale_outlined,
                        value: data?.totalWeightCollectedKg?.toStringAsFixed(0) ??
                            '0',
                        label: 'Weight Collected (kg)',
                        color: AppColors.accentDark,
                      ),
                      MetricTile(
                        icon: Icons.pending_actions_outlined,
                        value: '${data?.todayPending ?? 0}',
                        label: 'Pending Pickups',
                        color: AppColors.warningDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppButton(
                    text: 'View Optimal Route Map',
                    icon: const Icon(Icons.map_outlined, color: Colors.white),
                    onPressed: () => context.push('/collector-route'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => context.push('/chat'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Messages from Residents'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  SectionHeader(
                    title: 'Assigned Pickups',
                    subtitle: '${jobs.length} jobs today',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (jobs.isEmpty)
                    const EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'No Active Jobs',
                      description:
                          'Start your shift or wait for dispatch to assign pickup jobs.',
                    )
                  else
                    ResponsiveWrap(
                      minItemWidth: 340,
                      children: jobs.map((job) {
                        return _JobCard(
                          job: job,
                          onTap: () => context.push(
                            '/collector-job/${job.id}',
                            extra: job,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
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
        icon: Icons.map_outlined,
        label: 'Route Map',
        onTap: () => context.push('/collector-route'),
      ),
      ResponsiveDestination(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        onTap: () => context.push('/chat'),
      ),
      ResponsiveDestination(
        icon: Icons.account_circle_outlined,
        label: 'Profile',
        onTap: () => context.push('/profile'),
      ),
    ];

class _JobCard extends StatelessWidget {
  final CollectorJob job;
  final VoidCallback? onTap;

  const _JobCard({required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = statusVisual(job.status);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      job.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.category ?? 'General Waste',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                  job.address,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${job.distanceKm?.toStringAsFixed(1) ?? "1.2"} km away',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

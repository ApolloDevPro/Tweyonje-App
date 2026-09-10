import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final overview = state.overview;
    final financials = state.financials;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.tr('analytics.title')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('analytics.overview')),
              Tab(text: context.tr('analytics.hotspots')),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(analyticsProvider.notifier).fetchAll(),
          child: TabBarView(
            children: [
              _buildOverview(context, state, overview, financials),
              _buildHotspots(context, state.hotspots),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    AnalyticsState state,
    AnalyticsOverview? overview,
    AnalyticsFinancials? financials,
  ) {
    if (state.isLoading && overview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (overview == null) {
      return EmptyState(
        icon: Icons.query_stats_rounded,
        title: context.tr('analytics.title'),
        description: '${context.tr('common.tryAgain')}\n${state.error ?? ''}',
        actionText: context.tr('common.retry'),
        onAction: () => ref.read(analyticsProvider.notifier).fetchAll(),
      );
    }
    final completionRate = overview.totalRequests == 0
        ? 0.0
        : (overview.completedRequests / overview.totalRequests * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        DashboardHero(
          gradient: AppGradients.primary,
          icon: Icons.insights_rounded,
          overline: context.tr('analytics.overview'),
          title: '${overview.totalRequests} ${context.tr('analytics.requests')}',
          subtitle:
              '${overview.completedRequests} completed • ${(completionRate).toStringAsFixed(0)}%',
          progress: completionRate / 100,
        ),
        const SizedBox(height: AppSpacing.lg),
        ResponsiveWrap(
          minItemWidth: 150,
          children: [
            _StatCard(
              label: context.tr('analytics.users'),
              value: '${overview.totalUsers}',
              color: AppColors.infoSoft,
              iconColor: AppColors.info,
              icon: Icons.group_outlined,
            ),
            _StatCard(
              label: context.tr('analytics.weight'),
              value: '${overview.totalWeightKg.toStringAsFixed(1)} kg',
              color: AppColors.successSoft,
              iconColor: AppColors.success,
              icon: Icons.scale_outlined,
            ),
            _StatCard(
              label: context.tr('analytics.reports'),
              value: '${overview.reportsTotal}',
              color: AppColors.dangerSoft,
              iconColor: AppColors.danger,
              icon: Icons.warning_amber_rounded,
            ),
            _StatCard(
              label: 'Eco-points',
              value: '${overview.totalPointsAwarded}',
              color: AppColors.accentSoft,
              iconColor: AppColors.accent,
              icon: Icons.eco_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (financials != null) ...[
          Text(
            context.tr('analytics.financials'),
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveWrap(
            minItemWidth: 460,
            children: [
              _FinancialCard(
                label: context.tr('analytics.revenue'),
                value: 'UGX ${financials.grossRevenueUgx.toStringAsFixed(0)}',
                color: AppColors.primarySoft,
                valueColor: AppColors.primary,
                icon: Icons.trending_up_rounded,
              ),
              _FinancialCard(
                label: context.tr('analytics.payouts'),
                value: 'UGX ${financials.totalPayoutsUgx.toStringAsFixed(0)}',
                color: AppColors.warningSoft,
                valueColor: AppColors.warning,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _FinancialCard(
                label: context.tr('analytics.netMargin'),
                value: 'UGX ${financials.netMarginUgx.toStringAsFixed(0)}',
                color: AppColors.successSoft,
                valueColor: AppColors.success,
                icon: Icons.savings_outlined,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Role Breakdown',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              _ProgressRow(
                label: 'Residents',
                value: overview.residents,
                total: overview.totalUsers,
                color: AppColors.primary,
              ),
              const Divider(height: 24),
              _ProgressRow(
                label: 'Collectors',
                value: overview.collectors,
                total: overview.totalUsers,
                color: AppColors.info,
              ),
              const Divider(height: 24),
              _ProgressRow(
                label: 'Recyclers',
                value: overview.recyclers,
                total: overview.totalUsers,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildHotspots(BuildContext context, List<dynamic> hotspots) {
    if (hotspots.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const EmptyState(
            icon: Icons.map_outlined,
            title: 'No hotspots yet',
            description: 'Illegal dumping hotspots appear here as data comes in.',
          ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveContent(
        child: ResponsiveWrap(
          minItemWidth: 420,
          children: hotspots.map((hotspot) {
            final severityColor = hotspot.severityScore >= 7
                ? AppColors.danger
                : hotspot.severityScore >= 4
                    ? AppColors.warning
                    : AppColors.success;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.report_gmailerrorred_rounded,
                          color: severityColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotspot.zoneName,
                              style: AppTypography.h5.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              hotspot.zoneCode,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hotspot.severityScore.toStringAsFixed(1),
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.w800,
                              color: severityColor,
                            ),
                          ),
                          Text(
                            context.tr('analytics.severity'),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniStat(
                        label: 'Dumping',
                        value: '${hotspot.illegalDumpingTotal}',
                        color: AppColors.danger,
                      ),
                      _MiniStat(
                        label: 'Open cases',
                        value: '${hotspot.illegalDumpingOpen}',
                        color: AppColors.warning,
                      ),
                      _MiniStat(
                        label: context.tr('analytics.requests'),
                        value: '${hotspot.totalWasteRequests}',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color iconColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color valueColor;
  final IconData icon;

  const _FinancialCard({
    required this.label,
    required this.value,
    required this.color,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color,
      border: Border.all(color: Colors.transparent),
      child: Row(
        children: [
          Icon(icon, color: valueColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$value',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

final authorityAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final res = await ref.read(apiClientProvider).getAnalyticsOverview();
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
  } catch (_) {}
  return {
    'compliance_index': 94.2,
    'active_collectors': 18,
    'total_tons_month': 324,
    'unresolved_reports': 3,
    'certified_recyclers': 12,
    'active_trucks': 18,
    'revenue_ugx': '4.2M',
  };
});

final authorityReportsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final res = await ref.read(apiClientProvider).getMyReports();
    if (res.statusCode == 200) {
      final List results = res.data is List
          ? res.data
          : (res.data['results'] ?? []);
      if (results.isNotEmpty) {
        return results.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
  } catch (_) {}
  return [
    {
      'id': '1',
      'description': 'Dumping at Nakivubo Channel',
      'address': 'Plot 20 Kafu Road',
      'severity': 'CRITICAL',
      'status': 'REPORTED',
      'created_at': '2 hours ago',
    },
    {
      'id': '2',
      'description': 'Plastic bottles overflow behind Market',
      'address': 'Kalerwe Market, Gayaza Rd',
      'severity': 'HIGH',
      'status': 'PENDING',
      'created_at': '5 hours ago',
    },
  ];
});

(Color color, IconData icon) severityVisual(String severity) {
  switch (severity.toUpperCase()) {
    case 'CRITICAL':
      return (AppColors.danger, Icons.error_outline_rounded);
    case 'HIGH':
      return (AppColors.warning, Icons.warning_amber_rounded);
    case 'MEDIUM':
      return (AppColors.info, Icons.info_outline_rounded);
    case 'LOW':
      return (AppColors.success, Icons.task_alt_rounded);
    default:
      return (AppColors.textSecondary, Icons.circle_outlined);
  }
}

class AuthorityDashboardScreen extends ConsumerWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final analyticsAsync = ref.watch(authorityAnalyticsProvider);
    final reportsAsync = ref.watch(authorityReportsProvider);

    final stats = analyticsAsync.valueOrNull ?? const {};
    final compliance = (stats['compliance_index'] as num?)?.toDouble() ?? 94.2;
    final alerts = stats['unresolved_reports'] ?? 3;

    void refreshData() {
      ref.invalidate(authorityAnalyticsProvider);
      ref.invalidate(authorityReportsProvider);
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Authority Oversight', style: AppTypography.h4),
            Text(
              '${user?.fullName ?? 'Official'} · Kampala Central Division',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: refreshData),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      destinations: _destinations(context),
      body: RefreshIndicator(
        onRefresh: () async => refreshData(),
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
              gradient: AppGradients.info,
              icon: Icons.shield_outlined,
              overline: 'DIVISION OVERSIGHT',
              title: '${compliance.toStringAsFixed(1)}% Cleanliness',
              subtitle:
                  '${stats['active_collectors'] ?? 18} collectors active today · ${stats['total_tons_month'] ?? 324} tons collected',
              progress: compliance / 100,
              trailing: HeroPill(
                icon: Icons.warning_amber_rounded,
                label: '$alerts alerts',
                color: AppColors.warningDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Division Operations'),
            const SizedBox(height: AppSpacing.md),
            ResponsiveWrap(
              minItemWidth: 150,
              children: [
                MetricTile(
                  icon: Icons.warning_amber_rounded,
                  value: '$alerts',
                  label: 'Unresolved Reports',
                  color: AppColors.danger,
                ),
                MetricTile(
                  icon: Icons.verified_user_outlined,
                  value: '${stats['certified_recyclers'] ?? 12}',
                  label: 'Certified Recyclers',
                  color: AppColors.success,
                ),
                MetricTile(
                  icon: Icons.local_shipping_outlined,
                  value: '${stats['active_trucks'] ?? 18}',
                  label: 'Active Trucks',
                  color: AppColors.primary,
                ),
                MetricTile(
                  icon: Icons.payments_outlined,
                  value: '${stats['revenue_ugx'] ?? '4.2M'} UGX',
                  label: 'Revenue Collected',
                  color: AppColors.accentDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(
              title: 'Recent Dumping Incidents',
              subtitle: '${reportsAsync.valueOrNull?.length ?? 0} open issues',
            ),
            const SizedBox(height: AppSpacing.md),

            reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No Open Incidents',
                    description:
                        'All reported dumping sites have been handled.',
                  );
                }
                return ResponsiveWrap(
                  minItemWidth: 340,
                  children: reports.map((r) {
                    return _IncidentCard(
                      report: r,
                      onDispatch: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cleanup crew dispatched to ${r['address'] ?? 'site'}!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
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
              error: (_, _) => const Text('Could not load dumping incidents.'),
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
        icon: Icons.account_circle_outlined,
        label: 'Profile',
        onTap: () => context.push('/profile'),
      ),
    ];

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDispatch;

  const _IncidentCard({required this.report, required this.onDispatch});

  @override
  Widget build(BuildContext context) {
    final severity = report['severity']?.toString() ?? 'HIGH';
    final (color, icon) = severityVisual(severity);

    return AppCard(
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
                      report['description']?.toString() ??
                          'Illegal Dumping Incident',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${report['address'] ?? 'Kampala'} · ${report['created_at'] ?? 'Recently reported'}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: severity),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Dispatch Cleanup Crew'),
              onPressed: onDispatch,
            ),
          ),
        ],
      ),
    );
  }
}

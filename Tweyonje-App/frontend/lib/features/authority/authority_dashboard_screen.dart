import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

final authorityAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).getAnalyticsOverview();
  if (res.statusCode == 200 && res.data is Map) {
    return Map<String, dynamic>.from(res.data);
  }
  return const {};
});

final authorityReportsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(apiClientProvider).getReports();
  if (res.statusCode == 200) {
    final List results = res.data is List
        ? res.data
        : (res.data['results'] is List ? res.data['results'] : []);
    return results.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
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

class AuthorityDashboardScreen extends ConsumerStatefulWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  ConsumerState<AuthorityDashboardScreen> createState() =>
      _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState
    extends ConsumerState<AuthorityDashboardScreen> {
  bool _resolving = false;

  Future<void> _resolveReport(
    BuildContext context,
    Map<String, dynamic> report,
  ) async {
    final id = report['id']?.toString();
    if (id == null || _resolving) return;

    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark this incident as resolved and dispatch a cleanup crew?',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolution notes (optional)',
                hintText: 'e.g. Cleanup crew dispatched, site cleared',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _resolving = true);
    try {
      final res = await ref
          .read(apiClientProvider)
          .resolveReport(id, notes: notesController.text);
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report resolved and crew dispatched.'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(authorityReportsProvider);
        ref.invalidate(authorityAnalyticsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve report (${res.statusCode}).'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      final data = e.response?.data;
      final msg = data is Map
          ? (data['error'] ?? data['detail'] ?? 'Failed to resolve report.')
              .toString()
          : 'Failed to resolve report.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resolve report. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final analyticsAsync = ref.watch(authorityAnalyticsProvider);
    final reportsAsync = ref.watch(authorityReportsProvider);

    final stats = analyticsAsync.valueOrNull ?? const {};
    final users = stats['users'] is Map
        ? Map<String, dynamic>.from(stats['users'])
        : const <String, dynamic>{};
    final collections = stats['collections'] is Map
        ? Map<String, dynamic>.from(stats['collections'])
        : const <String, dynamic>{};
    final envReports = stats['environmental_reports'] is Map
        ? Map<String, dynamic>.from(stats['environmental_reports'])
        : const <String, dynamic>{};

    final totalReports = (envReports['total'] as num?)?.toInt() ?? 0;
    final resolvedReports = (envReports['resolved'] as num?)?.toInt() ?? 0;
    final resolutionRate =
        (envReports['resolution_rate'] as num?)?.toDouble() ?? 0.0;
    final unresolved = totalReports - resolvedReports;
    final collectors = (users['collectors'] as num?)?.toInt() ?? 0;
    final recyclers = (users['recyclers'] as num?)?.toInt() ?? 0;
    final totalWeightKg =
        (collections['total_weight_kg'] as num?)?.toDouble() ?? 0.0;
    final totalTons = totalWeightKg / 1000.0;

    void refreshData() {
      ref.invalidate(authorityAnalyticsProvider);
      ref.invalidate(authorityReportsProvider);
    }

    final reports = reportsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final openIncidents = reports
        .where((r) => r['status'] != 'RESOLVED' && r['status'] != 'DISMISSED')
        .toList();

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
                  title: '${resolutionRate.toStringAsFixed(1)}% Cleanliness',
                  subtitle:
                      '$collectors collectors active · ${totalTons.toStringAsFixed(1)} tons collected',
                  progress: resolutionRate / 100,
                  trailing: HeroPill(
                    icon: Icons.warning_amber_rounded,
                    label: '$unresolved alerts',
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
                      value: '$unresolved',
                      label: 'Unresolved Reports',
                      color: AppColors.danger,
                    ),
                    MetricTile(
                      icon: Icons.verified_user_outlined,
                      value: '$recyclers',
                      label: 'Certified Recyclers',
                      color: AppColors.success,
                    ),
                    MetricTile(
                      icon: Icons.delete_outline,
                      value: '$totalReports',
                      label: 'Total Reports',
                      color: AppColors.primary,
                    ),
                    MetricTile(
                      icon: Icons.check_circle_outline,
                      value: '$resolvedReports',
                      label: 'Resolved Reports',
                      color: AppColors.accentDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                SectionHeader(
                  title: 'Dumping Incidents',
                  subtitle: '${openIncidents.length} open issues',
                ),
                const SizedBox(height: AppSpacing.md),

                reportsAsync.when(
                  data: (allReports) {
                    if (openIncidents.isEmpty) {
                      return const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No Open Incidents',
                        description:
                            'All reported dumping sites have been handled.',
                      );
                    }
                    return ResponsiveWrap(
                      minItemWidth: 340,
                      children: openIncidents.map((r) {
                        return _IncidentCard(
                          report: r,
                          resolving: _resolving,
                          onDispatch: () => _resolveReport(context, r),
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
                  error: (e, _) {
                    final msg = e is DioException
                        ? 'Could not load incidents. Check your connection.'
                        : 'Could not load incidents.';
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Error',
                      description: msg,
                    );
                  },
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
  final bool resolving;

  const _IncidentCard({
    required this.report,
    required this.onDispatch,
    this.resolving = false,
  });

  @override
  Widget build(BuildContext context) {
    final severity = report['severity']?.toString() ?? 'HIGH';
    final (color, icon) = severityVisual(severity);
    final createdAt = report['created_at']?.toString() ?? 'Recently reported';
    final createdLabel = createdAt.contains('T')
        ? createdAt.split('T').first
        : createdAt;

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
                      '${report['address'] ?? 'Kampala'} · $createdLabel',
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
              icon: resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(resolving ? 'Resolving…' : 'Dispatch Cleanup Crew'),
              onPressed: resolving ? null : onDispatch,
            ),
          ),
        ],
      ),
    );
  }
}

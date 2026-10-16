import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

final collectorHistoryProvider =
    FutureProvider<List<CollectorJob>>((ref) async {
  final res =
      await ref.read(apiClientProvider).getAssignments(status: 'COMPLETED');
  if (res.statusCode == 200) {
    final List results = res.data is List
        ? res.data
        : (res.data['results'] is List ? res.data['results'] : []);
    return results
        .map((e) => CollectorJob.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  return [];
});

final collectorPayoutsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(apiClientProvider).getPayouts();
  if (res.statusCode == 200) {
    final List results = res.data is List
        ? res.data
        : (res.data['results'] is List ? res.data['results'] : []);
    return results.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
});

class CollectorHistoryScreen extends ConsumerWidget {
  const CollectorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(collectorHistoryProvider);
    final payoutsAsync = ref.watch(collectorPayoutsProvider);

    final history = historyAsync.valueOrNull ?? const <CollectorJob>[];
    final payouts = payoutsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    final totalEarned = payouts.fold<double>(0, (sum, p) {
      if (p['status'] == 'FAILED' || p['status'] == 'CANCELLED') return sum;
      return sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0);
    });
    final totalKg = history.fold<double>(0, (sum, j) {
      return sum + (j.estimatedWeightKg ?? 0);
    });
    final totalPayouts = payouts
        .where((p) => p['status'] == 'PAID' || p['status'] == 'PROCESSED')
        .length;

    String fmtUgx(double v) => v >= 1000000
        ? '${(v / 1000000).toStringAsFixed(1)}M'
        : v.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(collectorHistoryProvider);
              ref.invalidate(collectorPayoutsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collectorHistoryProvider);
          ref.invalidate(collectorPayoutsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveWrap(
                  minItemWidth: 150,
                  children: [
                    MetricTile(
                      icon: Icons.account_balance_wallet_outlined,
                      value: fmtUgx(totalEarned),
                      label: 'Total Earned (UGX)',
                      color: AppColors.success,
                    ),
                    MetricTile(
                      icon: Icons.task_alt_outlined,
                      value: '${history.length}',
                      label: 'Completed Jobs',
                      color: AppColors.primary,
                    ),
                    MetricTile(
                      icon: Icons.scale_outlined,
                      value: totalKg.toStringAsFixed(0),
                      label: 'Weight Collected (kg)',
                      color: AppColors.accentDark,
                    ),
                    MetricTile(
                      icon: Icons.payments_outlined,
                      value: '$totalPayouts',
                      label: 'Payouts Received',
                      color: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                SectionHeader(
                  title: 'Earnings & Payouts',
                  subtitle: '${payouts.length} payout records',
                ),
                const SizedBox(height: AppSpacing.md),
                if (payoutsAsync.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (payouts.isEmpty)
                  const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No Payouts Yet',
                    description:
                        'Payouts appear here after completed collections are processed.',
                  )
                else
                  ResponsiveWrap(
                    minItemWidth: 340,
                    children: payouts.map((p) {
                      return _PayoutCard(payout: p);
                    }).toList(),
                  ),
                const SizedBox(height: AppSpacing.xl),

                SectionHeader(
                  title: 'Completed Jobs',
                  subtitle: '${history.length} jobs',
                ),
                const SizedBox(height: AppSpacing.md),
                if (historyAsync.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (history.isEmpty)
                  const EmptyState(
                    icon: Icons.history_outlined,
                    title: 'No Completed Jobs',
                    description:
                        'Completed pickups will appear here once you finish them.',
                  )
                else
                  ResponsiveWrap(
                    minItemWidth: 340,
                    children: history.map((job) {
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.reference,
                                        style: AppTypography.h5.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        job.category ?? 'General Waste',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                if (job.estimatedWeightKg != null)
                                  Text(
                                    '${job.estimatedWeightKg!.toStringAsFixed(1)} kg',
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              job.address,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final Map<String, dynamic> payout;

  const _PayoutCard({required this.payout});

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(payout['amount']?.toString() ?? '0') ?? 0;
    final status = payout['status']?.toString() ?? 'PENDING';
    final amountLabel = amount >= 1000000
        ? '${(amount / 1000000).toStringAsFixed(1)}M'
        : amount.toStringAsFixed(0);
    final reference = payout['reference_id']?.toString() ?? '';
    final periodStart = payout['period_start']?.toString();
    final periodEnd = payout['period_end']?.toString();
    final (statusColor, statusIcon) = statusVisual(status);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$amountLabel UGX',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reference.isNotEmpty ? reference : 'Payout',
                  style: AppTypography.caption,
                ),
                if (periodStart != null && periodEnd != null)
                  Text(
                    '$periodStart → $periodEnd',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}

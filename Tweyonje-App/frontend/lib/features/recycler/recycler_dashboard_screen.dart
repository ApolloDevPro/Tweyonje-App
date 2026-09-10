import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

final recyclerAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final res = await ref.read(apiClientProvider).get(ApiEndpoints.myOffers);
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
  } catch (_) {}
  return {
    'total_offers': 24,
    'pending_offers': 5,
    'completed_transactions': 19,
    'total_revenue': '2.4M',
    'total_kg_collected': 1250,
    'active_suppliers': 18,
  };
});

final recyclerOffersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final res = await ref.read(apiClientProvider).get(ApiEndpoints.myOffers);
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
      'material_type': 'Plastic Bottles (PET)',
      'quantity': 50.0,
      'location': 'Kisaasi, Bukoto',
      'phone': '+256 770 123456',
      'status': 'PENDING',
      'created_at': '2 hours ago',
      'price_per_kg': 800,
    },
    {
      'id': '2',
      'material_type': 'Aluminium Cans',
      'quantity': 25.0,
      'location': 'Nakawa Market',
      'phone': '+256 770 789012',
      'status': 'PENDING',
      'created_at': '5 hours ago',
      'price_per_kg': 3500,
    },
    {
      'id': '3',
      'material_type': 'Cardboard',
      'quantity': 100.0,
      'location': 'Mukono Town',
      'phone': '+256 770 345678',
      'status': 'ACCEPTED',
      'created_at': '1 day ago',
      'price_per_kg': 400,
    },
  ];
});

final recyclerTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .get(ApiEndpoints.recyclingTransactions);
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
        'material_type': 'Plastic Bottles (PET)',
        'quantity': 80.0,
        'total_amount': 64000,
        'date': '2024-01-15',
        'supplier': 'John Doe',
      },
      {
        'id': '2',
        'material_type': 'Aluminium Cans',
        'quantity': 45.0,
        'total_amount': 157500,
        'date': '2024-01-14',
        'supplier': 'Jane Smith',
      },
    ];
  },
);

class RecyclerDashboardScreen extends ConsumerWidget {
  const RecyclerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final analyticsAsync = ref.watch(recyclerAnalyticsProvider);
    final offersAsync = ref.watch(recyclerOffersProvider);
    final transactionsAsync = ref.watch(recyclerTransactionsProvider);

    final stats = analyticsAsync.valueOrNull ?? const {};

    void refreshData() {
      ref.invalidate(recyclerAnalyticsProvider);
      ref.invalidate(recyclerOffersProvider);
      ref.invalidate(recyclerTransactionsProvider);
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recycler Hub', style: AppTypography.h4),
            Text(
              '${user?.fullName ?? 'Recycler'} · Certified Partner',
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
              gradient: AppGradients.accent,
              icon: Icons.recycling_rounded,
              overline: 'BUSINESS OVERVIEW',
              title: '${stats['total_revenue'] ?? '0'} UGX Revenue',
              subtitle:
                  '${stats['total_kg_collected'] ?? 0} kg collected · ${stats['active_suppliers'] ?? 0} active suppliers',
              trailing: HeroPill(
                icon: Icons.mark_email_unread_outlined,
                label: '${stats['pending_offers'] ?? 0} pending',
                color: AppColors.warningDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SectionHeader(title: 'Business Metrics'),
            const SizedBox(height: AppSpacing.md),
            ResponsiveWrap(
              minItemWidth: 150,
              children: [
                MetricTile(
                  icon: Icons.inbox_outlined,
                  value: '${stats['pending_offers'] ?? 0}',
                  label: 'Pending Offers',
                  color: AppColors.warning,
                ),
                MetricTile(
                  icon: Icons.check_circle_outline,
                  value: '${stats['completed_transactions'] ?? 0}',
                  label: 'Completed',
                  color: AppColors.success,
                ),
                MetricTile(
                  icon: Icons.local_offer_outlined,
                  value: '${stats['total_offers'] ?? 0}',
                  label: 'Total Offers',
                  color: AppColors.primary,
                ),
                MetricTile(
                  icon: Icons.payments_outlined,
                  value: '${stats['total_revenue'] ?? '0'} UGX',
                  label: 'Revenue',
                  color: AppColors.accentDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(
              title: 'New Offers from Residents',
              subtitle: 'Respond fast to win the deal',
            ),
            const SizedBox(height: AppSpacing.md),

            offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.recycling_rounded,
                    title: 'No New Offers',
                    description:
                        'Residents offering recyclables will appear here.',
                  );
                }
                return ResponsiveWrap(
                  minItemWidth: 340,
                  children: offers.map((offer) {
                    return _OfferCard(
                      offer: offer,
                      onAccept: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Offer accepted! Contact supplier at ${offer['phone']}',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      onDecline: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer declined'),
                            backgroundColor: AppColors.danger,
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
              error: (_, _) => const Text('Could not load offers.'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const SectionHeader(title: 'Recent Transactions'),
            const SizedBox(height: AppSpacing.md),

            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions Yet',
                    description: 'Completed deals will be recorded here.',
                  );
                }
                return ResponsiveWrap(
                  minItemWidth: 340,
                  children: transactions.map((txn) {
                    return _TransactionCard(txn: txn);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Text('Could not load transactions.'),
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

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _OfferCard({
    required this.offer,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final status = offer['status']?.toString() ?? 'PENDING';
    final (color, icon) = statusVisual(status);

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
                      offer['material_type']?.toString() ??
                          'Recyclable Material',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer['quantity'] ?? 0} kg · ${offer['location'] ?? 'Location'}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Offered ${offer['created_at'] ?? 'recently'}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                'UGX ${offer['price_per_kg'] ?? '--'}/kg',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (status == 'PENDING') ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    onPressed: onAccept,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.dangerLight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    onPressed: onDecline,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> txn;

  const _TransactionCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['material_type']?.toString() ?? 'Material',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${txn['quantity'] ?? 0} kg · ${txn['supplier'] ?? 'Supplier'}',
                  style: AppTypography.caption,
                ),
                Text(
                  txn['date']?.toString() ?? '',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${txn['total_amount'] ?? 0} UGX',
            style: AppTypography.h5.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

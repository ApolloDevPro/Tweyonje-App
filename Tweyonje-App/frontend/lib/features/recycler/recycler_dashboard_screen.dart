import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

final recyclerListingsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final res = await ref
        .read(apiClientProvider)
        .getMarketplaceListings();
    if (res.statusCode == 200) {
      final List results = res.data is List
          ? res.data
          : (res.data['results'] ?? []);
      return results.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  } catch (_) {}
  return [];
});

final recyclerTradeInsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final res = await ref.read(apiClientProvider).getTradeIns();
      if (res.statusCode == 200) {
        final List results = res.data is List
            ? res.data
            : (res.data['results'] ?? []);
        return results.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  },
);

Map<String, dynamic> _computeRecyclerStats(
  List<Map<String, dynamic>> listings,
  List<Map<String, dynamic>> tradeIns,
) {
  final pending = listings
      .where((l) => l['status'] == 'AVAILABLE' || l['status'] == 'RESERVED')
      .length;
  final completed = tradeIns
      .where((t) => t['status'] == 'COMPLETED')
      .length;
  final totalKg = tradeIns.fold<double>(0, (sum, t) {
    return sum + (double.tryParse(t['weight_kg']?.toString() ?? '0') ?? 0);
  });
  final totalRevenue = tradeIns.fold<double>(0, (sum, t) {
    if (t['status'] != 'COMPLETED') return sum;
    return sum + (double.tryParse(t['amount_paid_ugx']?.toString() ?? '0') ?? 0);
  });
  final suppliers = tradeIns
      .map((t) => t['user_details']?['id'])
      .where((id) => id != null)
      .toSet()
      .length;
  return {
    'total_offers': listings.length,
    'pending_offers': pending,
    'completed_transactions': completed,
    'total_revenue': totalRevenue >= 1000000
        ? '${(totalRevenue / 1000000).toStringAsFixed(1)}M'
        : totalRevenue.toStringAsFixed(0),
    'total_kg_collected': totalKg.toStringAsFixed(0),
    'active_suppliers': suppliers,
  };
}

class RecyclerDashboardScreen extends ConsumerWidget {
  const RecyclerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final listingsAsync = ref.watch(recyclerListingsProvider);
    final tradeInsAsync = ref.watch(recyclerTradeInsProvider);

    final listings = listingsAsync.valueOrNull ?? const [];
    final tradeIns = tradeInsAsync.valueOrNull ?? const [];
    final stats = _computeRecyclerStats(listings, tradeIns);

    void refreshData() {
      ref.invalidate(recyclerListingsProvider);
      ref.invalidate(recyclerTradeInsProvider);
    }

    Future<void> reserveListing(Map<String, dynamic> listing) async {
      final id = listing['id']?.toString();
      if (id == null) return;
      try {
        final res = await ref.read(apiClientProvider).reserveListing(id);
        if (res.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Listing reserved. Contact the seller to arrange pickup.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          refreshData();
        } else {
          final data = res.data;
          final msg = data is Map && data['error'] is String
              ? data['error'] as String
              : 'Could not reserve listing.';
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
            );
          }
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error. Please try again.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
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
              title: 'Marketplace Listings',
              subtitle: 'Reserve available recyclables from residents',
            ),
            const SizedBox(height: AppSpacing.md),

            listingsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.recycling_rounded,
                    title: 'No Listings Available',
                    description:
                        'Residents listing recyclables for sale will appear here.',
                  );
                }
                return ResponsiveWrap(
                  minItemWidth: 340,
                  children: items.map((listing) {
                    return _OfferCard(
                      offer: listing,
                      onAccept: () => reserveListing(listing),
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
              error: (_, _) => const Text('Could not load listings.'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const SectionHeader(title: 'Trade-In History'),
            const SizedBox(height: AppSpacing.md),

            tradeInsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Trade-Ins Yet',
                    description: 'Verified trade-ins will be recorded here.',
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
              error: (_, _) => const Text('Could not load trade-ins.'),
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
        icon: Icons.category_outlined,
        label: 'Materials',
        onTap: () => context.push('/recycler/resources'),
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

  const _OfferCard({
    required this.offer,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final status = offer['status']?.toString() ?? 'AVAILABLE';
    final (color, icon) = statusVisual(status);
    final materialName = offer['material_details'] is Map
        ? offer['material_details']['name']?.toString()
        : null;

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
                      offer['title']?.toString() ??
                          materialName ??
                          'Recyclable Material',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer['weight_kg'] ?? 0} kg · ${offer['location_address'] ?? 'Location'}',
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
                'Listed ${offer['created_at'] ?? 'recently'}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                'UGX ${offer['price_ugx'] ?? '--'}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (status == 'AVAILABLE') ...[
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
                    label: const Text('Reserve'),
                    onPressed: onAccept,
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
    final materialName = txn['material_details'] is Map
        ? txn['material_details']['name']?.toString()
        : null;
    final supplier = txn['user_details'] is Map
        ? txn['user_details']['full_name']?.toString()
        : null;
    final amount = txn['amount_paid_ugx'] ?? 0;
    final created = txn['created_at']?.toString() ?? '';

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
                  materialName ?? 'Material',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${txn['weight_kg'] ?? 0} kg${supplier != null ? ' · $supplier' : ''}',
                  style: AppTypography.caption,
                ),
                Text(
                  created.isEmpty
                      ? (txn['status']?.toString() ?? '')
                      : '${txn['status'] ?? ''} · $created',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amount UGX',
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

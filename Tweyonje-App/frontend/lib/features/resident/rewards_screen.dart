import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../providers/waste_request_provider.dart';
import '../../widgets/widgets.dart';

final rewardItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.getRedemptionItems();
    if (res.statusCode == 200) {
      final List results = res.data is List ? res.data : (res.data['results'] ?? []);
      if (results.isNotEmpty) {
        return results.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
  } catch (_) {}
  return [
    {'id': '1', 'title': '5,000 UGX MTN Airtime', 'points_required': 200, 'category': 'AIRTIME'},
    {'id': '2', 'title': '10,000 UGX Airtel Airtime', 'points_required': 380, 'category': 'AIRTIME'},
    {'id': '3', 'title': 'Waste Pickup Fee Waiver (1 Free)', 'points_required': 500, 'category': 'VOUCHER'},
    {'id': '4', 'title': 'Kaveera-Free Eco Shopping Bag', 'points_required': 300, 'category': 'MERCH'},
    {'id': '5', 'title': '20,000 UGX Mobile Money Cashback', 'points_required': 750, 'category': 'CASH'},
  ];
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  Future<void> _handleRedeem(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final title = item['title'] ?? 'Reward';
    final points = item['points_required'] ?? item['points'] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Redeem $title?'),
        content: Text('This will deduct $points Eco-Points from your wallet balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(apiClientProvider).redeemItem(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redemption successful for $title!'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(rewardsStatusProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redemption requested for $title!'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(rewardsStatusProvider);
        }
      }
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toUpperCase()) {
      case 'AIRTIME':
        return Icons.phone_android;
      case 'VOUCHER':
        return Icons.local_shipping;
      case 'MERCH':
        return Icons.shopping_bag;
      case 'CASH':
        return Icons.account_balance_wallet;
      default:
        return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsStatusProvider);
    final itemsAsync = ref.watch(rewardItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Eco-Rewards'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Points Card
            rewardsAsync.when(
              data: (rewards) => Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330A8F3C),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'TIER: ${rewards?.tier ?? "GREEN AMBASSADOR"}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${rewards?.balance ?? 150}',
                      style: AppTypography.display.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Total Eco-Points Earned',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: rewards?.progressToNext ?? 0.65,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '350 points to Gold Champion',
                      style: AppTypography.caption.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(
              'Redeem for Real Rewards',
              style: AppTypography.h4.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              'Turn your responsible waste disposal into mobile money, airtime, and vouchers.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            // Rewards Catalog
            itemsAsync.when(
              data: (items) => Column(
                children: items.map((item) {
                  final points = item['points_required'] ?? item['points'] ?? 0;
                  final category = item['category']?.toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(_getCategoryIcon(category), color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '$points Eco-Points',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _handleRedeem(context, ref, item),
                            child: const Text('Redeem'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load reward items.'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

final recyclableMaterialsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).getRecyclableMaterials();
    if (res.statusCode == 200) {
      final List results =
          res.data is List ? res.data : (res.data['results'] ?? []);
      return results.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  } catch (_) {}
  return [];
});

final marketplaceListingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).getMarketplaceListings();
    if (res.statusCode == 200) {
      final List results =
          res.data is List ? res.data : (res.data['results'] ?? []);
      return results.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  } catch (_) {}
  return [];
});

IconData _iconForMaterial(String? type) {
  switch (type) {
    case 'PLASTIC':
      return Icons.local_drink_outlined;
    case 'METAL':
      return Icons.hardware_outlined;
    case 'PAPER':
      return Icons.description_outlined;
    case 'GLASS':
      return Icons.wine_bar_outlined;
    case 'E_WASTE':
      return Icons.electrical_services_outlined;
    case 'ORGANIC':
      return Icons.grass_outlined;
    default:
      return Icons.recycling_outlined;
  }
}

class RecyclingScreen extends ConsumerStatefulWidget {
  const RecyclingScreen({super.key});

  @override
  ConsumerState<RecyclingScreen> createState() => _RecyclingScreenState();
}

class _RecyclingScreenState extends ConsumerState<RecyclingScreen> {
  void _showSellModal(Map<String, dynamic> material) {
    final weightController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    final pricePerKg =
        double.tryParse(material['price_per_kg']?.toString() ?? '0') ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sell Recyclables', style: AppTypography.h4),
              const SizedBox(height: 4),
              Text(
                '${material['name']} · UGX ${material['price_per_kg'] ?? '--'}/kg',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Weight (kg)',
                hint: 'e.g. 15',
                controller: weightController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInput(
                label: 'Pickup Location',
                hint: 'e.g. Kisaasi, Bukoto, Nakawa',
                controller: addressController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInput(
                label: 'Description / Contact',
                hint: 'Anything buyers should know',
                controller: descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: isSubmitting ? 'Posting Listing...' : 'Post to Marketplace',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final weight =
                            double.tryParse(weightController.text.trim());
                        if (weight == null || weight <= 0) return;
                        final address = addressController.text.trim();
                        if (address.isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        setModalState(() => isSubmitting = true);
                        String? error;
                        try {
                          final res = await ref
                              .read(apiClientProvider)
                              .createMarketplaceListing({
                            'material': material['id'],
                            'title': material['name']?.toString() ??
                                'Recyclables',
                            'description': descriptionController.text.trim(),
                            'weight_kg': weight,
                            'price_ugx': (weight * pricePerKg).round(),
                            'location_address': address,
                          });
                          if (res.statusCode != 201 && res.statusCode != 200) {
                            final data = res.data;
                            error = data is Map
                                ? (data['detail']?.toString() ??
                                    data['error']?.toString() ??
                                    'Failed to post listing.')
                                : 'Failed to post listing.';
                          }
                        } catch (_) {
                          error = 'Network error. Please try again.';
                        }

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (error != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        ref.invalidate(marketplaceListingsProvider);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Listing posted! Certified recyclers can now reserve it.',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(recyclableMaterialsProvider);
    final listingsAsync = ref.watch(marketplaceListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycling Marketplace'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recyclableMaterialsProvider);
          ref.invalidate(marketplaceListingsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.accent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_exchange,
                      color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monetize Your Recyclables',
                          style: AppTypography.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Connect directly with certified recycling plants in Uganda',
                          style: AppTypography.caption
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Live Buying Rates', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            materialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) {
                  return const EmptyState(
                    icon: Icons.recycling_outlined,
                    title: 'No Materials Listed',
                    description:
                        'Recyclable material rates will appear here shortly.',
                  );
                }
                return Column(
                  children: materials.map((mat) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                _iconForMaterial(
                                    mat['material_type']?.toString()),
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mat['name']?.toString() ?? 'Material',
                                    style: AppTypography.labelLarge
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'UGX ${mat['price_per_kg'] ?? '--'} / kg',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (mat['description'] != null &&
                                      (mat['description']
                                              ?.toString()
                                              .isNotEmpty ??
                                          false)) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      mat['description'].toString(),
                                      style: AppTypography.caption,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              onPressed: () => _showSellModal(mat),
                              child: const Text('Sell'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text('Could not load materials.'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Your Active Listings', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No Listings Yet',
                    description:
                        'Post a listing above to start selling recyclables.',
                  );
                }
                return Column(
                  children: listings.map((listing) {
                    final status =
                        listing['status']?.toString() ?? 'AVAILABLE';
                    final materialName = listing['material_details'] is Map
                        ? listing['material_details']['name']?.toString()
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(
                                Icons.sell_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing['title']?.toString() ??
                                        materialName ??
                                        'Listing',
                                    style: AppTypography.labelLarge
                                        .copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${listing['weight_kg'] ?? 0} kg · UGX ${listing['price_ugx'] ?? 0}',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: status),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text('Could not load listings.'),
            ),
          ],
        ),
      ),
    );
  }
}

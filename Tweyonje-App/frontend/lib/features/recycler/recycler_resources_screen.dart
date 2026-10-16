import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

final recyclerMaterialsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(apiClientProvider).getRecyclableMaterials();
  if (res.statusCode == 200) {
    final List results = res.data is List
        ? res.data
        : (res.data['results'] is List ? res.data['results'] : []);
    return results.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
});

final recyclerCentersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.read(apiClientProvider).getRecyclingCenters();
  if (res.statusCode == 200) {
    final List results = res.data is List
        ? res.data
        : (res.data['results'] is List ? res.data['results'] : []);
    return results.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
});

class RecyclerResourcesScreen extends ConsumerWidget {
  const RecyclerResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(recyclerMaterialsProvider);
    final centersAsync = ref.watch(recyclerCentersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials & Centers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(recyclerMaterialsProvider);
              ref.invalidate(recyclerCentersProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recyclerMaterialsProvider);
          ref.invalidate(recyclerCentersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Recyclable Materials',
                  subtitle: 'Accepted material types and base rates',
                ),
                const SizedBox(height: AppSpacing.md),
                materialsAsync.when(
                  data: (materials) {
                    if (materials.isEmpty) {
                      return const EmptyState(
                        icon: Icons.category_outlined,
                        title: 'No Materials Listed',
                        description:
                            'Recyclable material types will appear here.',
                      );
                    }
                    return ResponsiveWrap(
                      minItemWidth: 300,
                      children: materials.map((m) {
                        final price = m['base_price_per_kg'] ??
                            m['price_per_kg'] ??
                            m['default_price_per_kg'];
                        return AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.recycling_rounded,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m['name']?.toString() ?? 'Material',
                                      style: AppTypography.h5.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (m['description'] != null)
                                      Text(
                                        m['description'].toString(),
                                        style: AppTypography.caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (price != null)
                                Text(
                                  '$price UGX/kg',
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) =>
                      const Text('Could not load recyclable materials.'),
                ),
                const SizedBox(height: AppSpacing.xxl),

                const SectionHeader(
                  title: 'Recycling Centers',
                  subtitle: 'Drop-off and processing locations',
                ),
                const SizedBox(height: AppSpacing.md),
                centersAsync.when(
                  data: (centers) {
                    if (centers.isEmpty) {
                      return const EmptyState(
                        icon: Icons.location_on_outlined,
                        title: 'No Centers Listed',
                        description:
                            'Registered recycling centers will appear here.',
                      );
                    }
                    return ResponsiveWrap(
                      minItemWidth: 300,
                      children: centers.map((c) {
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(26),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.factory_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      c['name']?.toString() ??
                                          'Recycling Center',
                                      style: AppTypography.h5.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (c['address'] != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        c['address'].toString(),
                                        style: AppTypography.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (c['phone'] != null ||
                                  c['contact_phone'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (c['phone'] ?? c['contact_phone'])
                                          .toString(),
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const Text('Could not load recycling centers.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

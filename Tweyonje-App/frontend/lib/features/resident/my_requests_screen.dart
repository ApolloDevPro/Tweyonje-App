import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/waste_request_provider.dart';
import '../../widgets/widgets.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  String _filter = 'ALL';
  static const _activeStatuses = {
    'PENDING',
    'ASSIGNED',
    'SCHEDULED',
    'IN_PROGRESS',
    'EN_ROUTE',
  };

  List<WasteRequest> _applyFilter(List<WasteRequest> all) {
    switch (_filter) {
      case 'ACTIVE':
        return all
            .where((r) => _activeStatuses.contains(r.status.toUpperCase()))
            .toList();
      case 'COMPLETED':
        return all
            .where(
              (r) =>
                  r.status.toUpperCase() == 'COMPLETED' ||
                  r.status.toUpperCase() == 'COLLECTED',
            )
            .toList();
      case 'CANCELLED':
        return all
            .where(
              (r) =>
                  r.status.toUpperCase() == 'CANCELLED' ||
                  r.status.toUpperCase() == 'REJECTED',
            )
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(wasteRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Requests')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(wasteRequestsProvider.notifier).fetchRequests(),
        child: requestsAsync.when(
          data: (all) {
            final requests = _applyFilter(all);
            return Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ACTIVE', 'Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('COMPLETED', 'Completed'),
                        const SizedBox(width: 8),
                        _buildFilterChip('CANCELLED', 'Cancelled'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: requests.isEmpty
                      ? EmptyState(
                          icon: Icons.local_shipping_outlined,
                          title: _filter == 'ALL'
                              ? 'No Requests Yet'
                              : 'No $_filter Requests',
                          description: _filter == 'ALL'
                              ? 'Request waste collection from your home or business.'
                              : 'You have no requests in this category.',
                          actionText: 'Request Collection',
                          onAction: () => context.push('/create-request'),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1080),
                              child: ResponsiveWrap(
                                minItemWidth: 360,
                                runSpacing: 10,
                                children: requests
                                    .map((req) => _RequestCard(request: req))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading requests: $err'),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(wasteRequestsProvider.notifier).fetchRequests(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: AppTypography.label.copyWith(
        color: selected ? Colors.white : AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final WasteRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isActive = {
      'PENDING',
      'ASSIGNED',
      'SCHEDULED',
      'IN_PROGRESS',
      'EN_ROUTE',
    }.contains(request.status.toUpperCase());

    return AppCard(
      onTap: () =>
          context.push('/request-detail/${request.id}', extra: request),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.categoryDetails?.name ?? 'Waste Request',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: request.status),
            ],
          ),
          if (request.referenceId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              request.referenceId,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
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
                  request.pickupAddress,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isActive ? Icons.schedule_rounded : Icons.history_rounded,
                size: 16,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.scheduledDate ?? request.createdAt ?? '',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${request.estimatedWeightKg} kg • UGX ${request.estimatedPrice.toStringAsFixed(0)}',
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

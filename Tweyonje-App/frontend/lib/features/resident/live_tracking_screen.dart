import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const LiveTrackingScreen({super.key, required this.requestId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.6,
      upperBound: 1.2,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider(widget.requestId).notifier).start();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider(widget.requestId));
    final location = state.location;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('tracking.title')),
        actions: [
          if (state.isLive)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: AppTypography.label.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trackingProvider(widget.requestId).notifier).fetch(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 320,
                  child: AppMap(
                    initialLat: location?.latitude ?? 0.3476,
                    initialLng: location?.longitude ?? 32.5825,
                    initialZoom: 14.0,
                    interactive: true,
                    markers: location == null
                        ? const []
                        : [
                            AppMapMarker(
                              latitude: location.latitude,
                              longitude: location.longitude,
                              icon: Icons.local_shipping_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                  ),
                ),
                if (location == null)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.overlayLight,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (location != null)
              Column(
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('tracking.collector'),
                                style: AppTypography.h5.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${location.latitude.toStringAsFixed(5)}, '
                                '${location.longitude.toStringAsFixed(5)}'
                                '${location.lastUpdated != null ? ' • ${location.lastUpdated}' : ''}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.route_rounded,
                          label: context.tr('tracking.distance'),
                          value: location.distanceKm != null
                              ? '${location.distanceKm!.toStringAsFixed(1)} km'
                              : '—',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.schedule_rounded,
                          label: context.tr('tracking.eta'),
                          value: location.etaMinutes != null
                              ? '${location.etaMinutes} min'
                              : '—',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.badge_outlined,
                          label: context.tr('tracking.status'),
                          value: (location.status ?? 'EN_ROUTE')
                              .replaceAll('_', ' '),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else ...[
              AppCard(
                child: Row(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 3),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        context.tr('tracking.noLocation'),
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Refreshing every 20s automatically.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
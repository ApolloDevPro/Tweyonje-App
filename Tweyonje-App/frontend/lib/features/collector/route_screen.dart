import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/collector_provider.dart';
import '../../widgets/widgets.dart';

class RouteScreen extends ConsumerWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(collectorDashboardProvider);
    final data = dashboardAsync.valueOrNull;
    final jobs = (data?.jobs ?? const <CollectorJob>[])
        .where((j) => j.latitude != null && j.longitude != null)
        .toList();

    const base = LatLng(0.3476, 32.5825);
    final jobLatLngs = jobs
        .map((j) => LatLng(j.latitude!, j.longitude!))
        .toList();
    final waypoints = [base, ...jobLatLngs];

    final markers = <AppMapMarker>[
      const AppMapMarker(
        latitude: 0.3476,
        longitude: 32.5825,
        title: 'Current Location',
        icon: Icons.local_shipping,
        color: AppColors.primaryDark,
      ),
      for (var i = 0; i < jobs.length; i++)
        AppMapMarker(
          latitude: jobs[i].latitude!,
          longitude: jobs[i].longitude!,
          title: 'Stop ${i + 1}: ${jobs[i].reference}',
          icon: Icons.looks_one,
          color: AppColors.primary,
        ),
    ];

    final totalKm = jobs.fold<double>(0, (sum, j) => sum + (j.distanceKm ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Shift Route'),
      ),
      body: Stack(
        children: [
          AppMap(
            initialLat: 0.3580,
            initialLng: 32.5850,
            initialZoom: 13.5,
            markers: markers,
            polylinePoints: waypoints,
          ),

          if (jobs.isEmpty)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: AppCard(
                child: const EmptyState(
                  icon: Icons.map_outlined,
                  title: 'No Active Jobs',
                  description:
                      'Start your shift to see your optimized pickup route here.',
                ),
              ),
            )
          else
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Route Summary', style: AppTypography.h5),
                            Text(
                              '${jobs.length} Pickups • ${totalKm > 0 ? totalKm.toStringAsFixed(1) : '--'} km total',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'LIVE ROUTE',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.successDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Navigate to Next Stop (${jobs.first.reference})',
                      icon: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo collection route waypoints across central Kampala
    final waypoints = [
      const LatLng(0.3476, 32.5825), // Collector Base
      const LatLng(0.3520, 32.5870), // Stop 1: Nakasero
      const LatLng(0.3580, 32.5930), // Stop 2: Kololo
      const LatLng(0.3640, 32.5890), // Stop 3: Kamwokya
      const LatLng(0.3700, 32.5750), // Stop 4: Mulago
    ];

    final markers = [
      const AppMapMarker(latitude: 0.3476, longitude: 32.5825, title: 'Current Location', icon: Icons.local_shipping, color: AppColors.primaryDark),
      const AppMapMarker(latitude: 0.3520, longitude: 32.5870, title: 'Stop 1: #REQ-901', icon: Icons.looks_one, color: AppColors.primary),
      const AppMapMarker(latitude: 0.3580, longitude: 32.5930, title: 'Stop 2: #REQ-902', icon: Icons.looks_two, color: AppColors.primary),
      const AppMapMarker(latitude: 0.3640, longitude: 32.5890, title: 'Stop 3: #REQ-903', icon: Icons.looks_3, color: AppColors.primary),
      const AppMapMarker(latitude: 0.3700, longitude: 32.5750, title: 'Stop 4: #REQ-904', icon: Icons.looks_4, color: AppColors.primary),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Shift Route'),
      ),
      body: Stack(
        children: [
          // Map Background
          AppMap(
            initialLat: 0.3580,
            initialLng: 32.5850,
            initialZoom: 13.5,
            markers: markers,
            polylinePoints: waypoints,
          ),

          // Bottom Route Summary Card
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
                          Text('4 Pickups • 14.2 km total', style: AppTypography.caption),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'SAVING 25% FUEL',
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
                    text: 'Navigate to Next Stop (Stop 1)',
                    icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
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

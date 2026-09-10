import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/theme.dart';

class AppMapMarker {
  final double latitude;
  final double longitude;
  final String? title;
  final IconData icon;
  final Color color;

  const AppMapMarker({
    required this.latitude,
    required this.longitude,
    this.title,
    this.icon = Icons.location_on,
    this.color = AppColors.primary,
  });
}

class AppMap extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final List<AppMapMarker> markers;
  final List<LatLng> polylinePoints;
  final void Function(LatLng point)? onTap;
  final bool interactive;

  const AppMap({
    super.key,
    this.initialLat = 0.3476, // Kampala, Uganda default
    this.initialLng = 32.5825,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.polylinePoints = const [],
    this.onTap,
    this.interactive = true,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(widget.initialLat, widget.initialLng),
          initialZoom: widget.initialZoom,
          interactionOptions: InteractionOptions(
            flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
          ),
          onTap: widget.onTap != null ? (_, point) => widget.onTap!(point) : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ug.tweyonje.app',
            tileProvider: CancellableNetworkTileProvider(),
          ),
          if (widget.polylinePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.polylinePoints,
                  strokeWidth: 4.0,
                  color: AppColors.primary,
                ),
              ],
            ),
          MarkerLayer(
            markers: widget.markers.map((m) {
              return Marker(
                point: LatLng(m.latitude, m.longitude),
                width: 44,
                height: 44,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: m.color,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        m.icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

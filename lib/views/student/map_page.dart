import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';

import '../../core/services/map_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo_utils.dart';
import '../../data/models/route_model.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../widgets/campus_map.dart';
import '../../widgets/common.dart';
import '../../widgets/route_card.dart';
import '../../widgets/vehicle_marker.dart';

/// Full-screen map of one route: its polyline, stops, and live vehicles.
class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.routeId});
  final String routeId;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    // Opened from a deep link the shell may not have started the streams yet.
    context.read<MapViewModel>().start();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final route = vm.routeById(widget.routeId);
    if (route == null && vm.routes.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (route == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(icon: Icons.route_rounded, title: 'Route not found'),
        ),
      );
    }
    final color = AppColors.parseHex(route.color);
    final vehicles = vm.vehiclesOnRoute(route.id);

    return Scaffold(
      body: Stack(
        children: [
          CampusMap(
            controller: _map,
            routes: [route],
            highlightedRouteId: route.id,
            userLocation: vm.userLocation,
            showLandmarks: false,
            initialFit: MapService.fit(route.path, padding: const EdgeInsets.fromLTRB(48, 120, 48, 340)),
            children: [AnimatedVehicleLayer(vehicles: vehicles)],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MapFab(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Pod(
                      raised: true,
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(
                        children: [
                          Icon(vehicleIcon(route.type), color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  route.shortName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                                ),
                                Text(
                                  route.summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.85,
            builder: (context, scroll) => Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: Text(route.name.replaceAll('--', '·'), style: Theme.of(context).textTheme.titleLarge)),
                      StatusPill(
                        label: vehicles.isEmpty ? 'No live vehicles' : '${vehicles.length} live',
                        color: vehicles.isEmpty ? AppColors.offline : AppColors.onTime,
                        icon: vehicles.isEmpty ? null : Icons.sensors_rounded,
                      ),
                    ],
                  ),
                  if (vehicles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final v in vehicles)
                          ActionChip(
                            avatar: Icon(vehicleIcon(v.type), size: 16, color: AppColors.forVehicle(v.type)),
                            label: Text(
                              '${v.vehicleNumber}${v.distanceMeters == null ? '' : ' · ${formatDistance(v.distanceMeters!)}'}',
                            ),
                            onPressed: () => _map.move(v.position!, 17),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: '${route.stops.length} stops${route.isLoop ? ' · loop' : ''}',
                    subtitle: vehicles.isEmpty ? null : 'Next vehicle ETA to each stop',
                  ),
                  const SizedBox(height: 8),
                  StopTimeline(
                    stops: route.stops,
                    color: color,
                    trailing: (stop, _) => _nextEta(stop, vehicles.map((v) => v.position!).toList()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _nextEta(RouteStop stop, List<LatLng> positions) {
    if (positions.isEmpty) return null;
    final nearest = positions.map((p) => distanceMeters(p, stop.position)).reduce((a, b) => a < b ? a : b);
    return formatEta(etaMinutes(nearest));
  }
}

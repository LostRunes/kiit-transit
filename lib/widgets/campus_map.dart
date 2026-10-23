import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/campus_locations.dart';
import '../core/services/map_service.dart';
import '../core/theme/app_colors.dart';
import '../data/models/request_model.dart';
import '../data/models/route_model.dart';

/// The campus base map: tiles, route polylines, landmarks and the viewer's
/// position. Screens stack their own layers (vehicles, demand) via [children].
class CampusMap extends StatelessWidget {
  const CampusMap({
    super.key,
    this.controller,
    this.routes = const [],
    this.highlightedRouteId,
    this.userLocation,
    this.showLandmarks = true,
    this.children = const [],
    this.initialCenter,
    this.initialZoom,
    this.initialFit,
    this.onTap,
  });

  final MapController? controller;
  final List<RouteModel> routes;
  final String? highlightedRouteId;
  final LatLng? userLocation;
  final bool showLandmarks;
  final List<Widget> children;
  final LatLng? initialCenter;
  final double? initialZoom;
  final CameraFit? initialFit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final highlighted = routes.where((r) => r.id == highlightedRouteId).firstOrNull;
    final options = MapService.options(
      center: initialCenter,
      zoom: initialZoom,
      onTap: onTap == null ? null : (_, _) => onTap!(),
    );

    return FlutterMap(
      mapController: controller,
      options: initialFit == null
          ? options
          : MapOptions(
              initialCameraFit: initialFit,
              minZoom: options.minZoom,
              maxZoom: options.maxZoom,
              cameraConstraint: options.cameraConstraint,
              interactionOptions: options.interactionOptions,
              onTap: options.onTap,
            ),
      children: [
        MapService.tileLayer(brightness),
        if (routes.isNotEmpty)
          PolylineLayer(
            polylines: [
              for (final r in routes)
                if (r.id != highlightedRouteId)
                  Polyline(
                    points: r.path,
                    strokeWidth: 4,
                    color: AppColors.parseHex(r.color).withValues(alpha: highlighted == null ? 0.55 : 0.18),
                  ),
              if (highlighted != null) ...[
                Polyline(points: highlighted.path, strokeWidth: 9, color: Colors.white.withValues(alpha: 0.9)),
                Polyline(points: highlighted.path, strokeWidth: 5.5, color: AppColors.parseHex(highlighted.color)),
              ],
            ],
          ),
        if (highlighted != null)
          CircleLayer(
            circles: [
              for (final s in highlighted.stops)
                CircleMarker(
                  point: s.position,
                  radius: 6,
                  color: Colors.white,
                  borderColor: AppColors.parseHex(highlighted.color),
                  borderStrokeWidth: 3,
                ),
            ],
          ),
        if (showLandmarks) const _LandmarkLayer(),
        if (userLocation != null) UserLocationLayer(position: userLocation!),
        ...children,
        MapService.attribution(),
      ],
    );
  }
}

class _LandmarkLayer extends StatelessWidget {
  const _LandmarkLayer();

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    final showNames = zoom >= 16.2;
    return MarkerLayer(
      markers: [
        for (final l in CampusLocations.all)
          Marker(
            point: l.position,
            width: showNames ? 120 : 26,
            height: showNames ? 44 : 26,
            alignment: showNames ? const Alignment(0, 0.4) : Alignment.center,
            child: Tooltip(
              message: l.name,
              triggerMode: TooltipTriggerMode.tap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Icon(l.type.icon, size: 13, color: AppColors.secondary),
                  ),
                  if (showNames)
                    Text(
                      l.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        shadows: [Shadow(color: Colors.white, blurRadius: 3)],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pulsing blue dot for the viewer.
class UserLocationLayer extends StatelessWidget {
  const UserLocationLayer({super.key, required this.position});
  final LatLng position;

  @override
  Widget build(BuildContext context) => MarkerLayer(
    markers: [Marker(point: position, width: 44, height: 44, child: const _PulsingDot())],
  );
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 16 + 28 * _c.value,
            height: 16 + 28 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blue.withValues(alpha: 0.3 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Demand signals drawn as sized, colour-coded crowd markers.
class DemandLayer extends StatelessWidget {
  const DemandLayer({super.key, required this.requests, this.onTap});

  final List<RequestModel> requests;
  final ValueChanged<RequestModel>? onTap;

  static Color colorFor(RequestModel r) => switch (r.level) {
    3 => AppColors.cancelled,
    2 => AppColors.delayed,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      CircleLayer(
        circles: [
          for (final r in requests)
            CircleMarker(
              point: r.position,
              radius: 40 + r.studentCount * 6.0,
              useRadiusInMeter: true,
              color: colorFor(r).withValues(alpha: 0.18),
              borderColor: colorFor(r).withValues(alpha: 0.6),
              borderStrokeWidth: 1.5,
            ),
        ],
      ),
      MarkerLayer(
        markers: [
          for (final r in requests)
            Marker(
              point: r.position,
              width: 64,
              height: 30,
              child: GestureDetector(
                onTap: onTap == null ? null : () => onTap!(r),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorFor(r),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        '${r.studentCount}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

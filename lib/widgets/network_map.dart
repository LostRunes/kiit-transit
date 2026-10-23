import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/services/map_service.dart';
import '../core/theme/app_colors.dart';
import '../data/models/network_model.dart';

/// A traced line on the network map.
class NetworkLine {
  const NetworkLine({required this.points, required this.color, this.dashed = false, this.width = 5});

  final List<LatLng> points;
  final Color color;
  final bool dashed;
  final double width;
}

/// Region-wide map (Bhubaneswar, Cuttack, Khordha, Puri, Konark) that traces
/// routes or journeys with their stops.
class NetworkMap extends StatelessWidget {
  const NetworkMap({
    super.key,
    required this.lines,
    this.stops = const [],
    this.highlightStops = const {},
    this.controller,
    this.padding = const EdgeInsets.all(40),
    this.onStopTap,
  });

  final List<NetworkLine> lines;
  final List<NetworkStop> stops;

  /// Stop ids drawn larger (boarding, changes, destination).
  final Set<String> highlightStops;
  final MapController? controller;
  final EdgeInsets padding;
  final ValueChanged<NetworkStop>? onStopTap;

  static final _bounds = LatLngBounds(const LatLng(19.70, 85.50), const LatLng(20.62, 86.20));

  @override
  Widget build(BuildContext context) {
    final points = [for (final l in lines) ...l.points, for (final s in stops) s.position];
    final scheme = Theme.of(context).colorScheme;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCameraFit: points.length < 2 ? null : CameraFit.coordinates(coordinates: points, padding: padding, maxZoom: 16.5),
        initialCenter: points.isEmpty ? const LatLng(20.30, 85.82) : points.first,
        initialZoom: 12,
        minZoom: 9,
        maxZoom: 18.5,
        cameraConstraint: CameraConstraint.containCenter(bounds: _bounds),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        MapService.tileLayer(Theme.of(context).brightness),
        PolylineLayer(
          polylines: [
            for (final l in lines)
              Polyline(points: l.points, strokeWidth: l.width + 3.5, color: Colors.white.withValues(alpha: 0.85)),
            for (final l in lines)
              Polyline(
                points: l.points,
                strokeWidth: l.width,
                color: l.color,
                pattern: l.dashed ? StrokePattern.dashed(segments: const [8, 6]) : const StrokePattern.solid(),
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final s in stops)
              Marker(
                point: s.position,
                width: highlightStops.contains(s.id) ? 22 : 14,
                height: highlightStops.contains(s.id) ? 22 : 14,
                child: GestureDetector(
                  onTap: onStopTap == null ? null : () => onStopTap!(s),
                  child: Tooltip(
                    message: s.approximate ? '${s.name} (approx. position)' : s.name,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: highlightStops.contains(s.id) ? AppColors.primary : scheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: highlightStops.contains(s.id) ? Colors.white : AppColors.primary,
                          width: highlightStops.contains(s.id) ? 3 : 2.5,
                        ),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        MapService.attribution(),
      ],
    );
  }
}
